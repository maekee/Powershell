#This is just a function that lists Windows Firewall Rules
#So i in a simple way can find rules when searching, see example below function too find the interesting rules

Function Get-WinFWRuleList {
    [CmdletBinding()]
    param(
        [switch]$OnlyEnabled
    )

    $AllRules = @{}
    Get-NetFirewallRule | Foreach { [void]$AllRules.Add($_.Name,$_) }

    $AppRules = @{}
    Get-NetFirewallApplicationFilter | Select InstanceID,Program,Package | Foreach {[void]$AppRules.Add($_.InstanceID,$_)}

    $ScopeRules = @{}
    Get-NetFirewallAddressFilter | Select InstanceID,LocalIP,RemoteIP,LocalAddress,RemoteAddress | Foreach {[void]$ScopeRules.Add($_.InstanceID,$_)}

    $RuleList = Get-NetFirewallPortFilter | Select `
        @{name="RuleName";expression={ $AllRules.$($_.InstanceID).DisplayName }},
        @{name="Enabled";expression={ [bool]$AllRules.$($_.InstanceID).Enabled }},
        @{name="Action";expression={ $AllRules.$($_.InstanceID).Action }},
        @{name="Program";expression={ $AppRules.$($_.InstanceID).Program }},
        @{name="Package";expression={ $AppRules.$($_.InstanceID).Package }},
        @{name="DisplayGroup";expression={ $AllRules.$($_.InstanceID).DisplayGroup }},
        @{name="Profile";expression={ $AllRules.$($_.InstanceID).Profile }},
        @{name="Direction";expression={ $AllRules.$($_.InstanceID).Direction }},
        @{name="LocalAddress";expression={ $ScopeRules.$($_.InstanceID).LocalAddress }},
        @{name="RemoteAddress";expression={ $ScopeRules.$($_.InstanceID).RemoteAddress }},
        LocalPort,
        Protocol
        
        if($OnlyEnabled){$RuleList = $RuleList | Where {$_.Enabled -eq "True"}}
        $RuleList
}

#Example:
Get-WinFWRuleList | Where {$_.Enabled -and $_.Direction -eq "InBound"} | Sort RuleName | Select RuleName,Enabled,Action,Program,DisplayGroup,Profile,Direction,LocalAddress,RemoteAddress | Where {
    $_.DisplayGroup -notmatch "^Remote Desktop|^Hyper-V Management Clients$|^Network Discovery$|^File and Printer Sharing$|^Core Networking$|^Windows Management Instrumentation (WMI)|^Failover Clusters$" -and
    $_.DisplayGroup -notmatch "^File Server Remote Management$|^Windows Remote Management$|System Center 2012 R2 Configuration Manager"
} | ft
