#These functions are used to troubleshoot the Windows Firewall by enabling audit event logs for the Windows Filtering Platform.
#I wrote this function because when we are troubleshooting the Windows Firewall we dont see everything, hopefully this helps.

Function Get-WFPEvents{
    <# 
    .SYNOPSIS
        Gets Windows Filtering Platform events and enriches the events
    .DESCRIPTION
        The function gets Windows Filtering Platform (WFP) events from the Security event log.
        Furthermore enriches the events with combined information from running processes, local interface names, Windows Firewall rules and more
    .PARAMETER StartDate
        From what time the events should be collected, default one hour back from now
    .PARAMETER EndDate
        Until what time the events should be collected, default now
    .PARAMETER Direction 
        Post-filter, values are Inbound, Outbound and Everything. Default is Everything
    .PARAMETER SkipICMP
        Post-filter to remove all IPv4/IPv6 ICMP events from the result list
    .PARAMETER SkipWebBrowsers 
        Post-filter to remove events of known web browser process from the result list
    .PARAMETER SkipBroadCastMultiCastAndSSDP 
        Post-filter to remove known broadcasts/multicasts and SSDP (Simple Service Discovery Protocol) events from the result list
    .PARAMETER SkipIPHTTPSInterface 
        Post-filter to remove IP HTTPS Interface events from the result list
    .NOTES
        AUTHOR: Micke Sundqvist
        LASTEDIT: 2020-04-14
        VERSION: 1.0
        PREREQUISITE: Admin permission to read from the Security event log
        CHANGELOG: 1.0.0 - Initial Release
                   1.1.0 - Fixed bug where netsh wfp-command throwed exception random times. Think it was because i stored in clipboard, so i saved to file instead
		   1.2.0 - Added a bit of error handling, because an ordinary user cannot read the security by default.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][datetime]$StartDate = (Get-Date).AddHours(-1),
        [Parameter(Mandatory=$false)][datetime]$EndDate = (Get-Date),
        [ValidateSet('Inbound','Outbound','Everything')]$Direction = 'Everything',
        [Parameter(Mandatory=$false)][switch]$SkipICMP,
        [Parameter(Mandatory=$false)][switch]$SkipWebBrowsers,
        [Parameter(Mandatory=$false)][switch]$SkipBroadCastMultiCastAndSSDP,
        [Parameter(Mandatory=$false)][switch]$SkipIPHTTPSInterface
    )

    #region Build EventLog filters and get events to $EventsFound
        $EventFilters = @{
            LogName = 'Security'
            StartTime = $StartDate
            EndTime = $EndDate
            Id='5152','5153','5154','5155','5156','5157','5158','5159'
        }

        Write-Verbose -Message "Getting events from security log between $($StartDate.ToString("yyyy-MM-dd HH:mm:ss")) and $($EndDate.ToString("yyyy-MM-dd HH:mm:ss"))..."
        try{
            $EventsFound = Get-WinEvent -FilterHashTable $EventFilters -ErrorAction SilentlyContinue -Verbose:$false

            if($EventsFound.Count -gt 0){
                Write-Verbose -Message "Found $($EventsFound.Count) events"
            }
        }
        catch{ Write-Warning "Error occurred while getting windows security event logs from $($env:COMPUTERNAME), make sure you have the correct permissions in the security event log" }
    #endregion

    if($EventsFound){
        #region Convert to XML
            Write-Verbose -Message "Converting events to XML and building WFPEvent array..."
            [xml]$xmlEventsFound = '<events>'+$EventsFound.ToXml()+'</events>'
        #endregion

        #region Get current WinFW filters (rules) and add them to hash table
            try{
                Write-Verbose -Message "Getting current active network filters from Windows Filtering Platform..."
                $tmp1fil = [System.IO.Path]::GetTempFileName()
                netsh wfp show filters $tmp1fil | Out-Null
                [xml]$currentWinFWfilters = Get-Content -Path $tmp1fil

                $currentWinFWfiltersHash = @{}
                $currentWinFWfilters.wfpdiag.filters.item | foreach {
                    if($_.filterId -ne $null){ [void]$currentWinFWfiltersHash.Add($_.filterId,"$($_.displayData.name)" ) }
                }
                
                Remove-Item -Path $tmp1fil -Force
                }
            catch{ Write-Warning "Exception occurred while getting Windows Filtering Platform filters (rules). Exception: $($_.Exception.Message)" }
        #endregion

        #region Get current Layer info and add them to hash table
            try{
                Write-Verbose -Message "Getting current active network state from Windows Filtering Platform..."
                $tmp2fil = [System.IO.Path]::GetTempFileName()
                netsh wfp show state $tmp2fil | Out-Null
                [xml]$currentWinFWstate = Get-Content -Path $tmp2fil

                $currentWinFWstateHash = @{}
                $currentWinFWstate.wfpstate.layers.Item.layer | foreach {
                    if($_.layerId){ [void]$currentWinFWstateHash.Add($_.layerId,"$($_.displayData.name)" ) }
                }
                
                Remove-Item -Path $tmp2fil -Force
            }
            catch{ Write-Warning "Exception occurred while getting Windows Filtering Platform State. Exception: $($_.Exception.Message)" }
        #endregion

        #region Get Current Addresses
            $LocalAddresses = @{}

            Get-NetIPAddress | Foreach {
                if($_.IPAddress -match ":"){$Prefix = "IPv6"}else{$Prefix = "IPv4"}
                $LocalAddresses.Add($_.IPAddress,"$($env:COMPUTERNAME)-$Prefix-$($_.InterfaceAlias -replace '\*','')")
            }
        #endregion

        #region Protocol integer mapper
            #https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
            $ProtocolMapper = @{
                1 = 'ICMP'
                3 = 'Gateway-Gateway Protocol'
                6 = 'TCP'
                8 = 'Exterior Gateway Protocol'
                12 = 'PARC Universal Packet Protocol'
                17 = 'UDP'
                20 = 'Host Monitoring Protocol'
                27 = 'Reliable Datagram Protocol'
                46 = 'Reservation Protocol (RSVP) QoS'
                47 = 'PPTP data over GRE'
                50 = 'IPSec ESP'
                51 = 'IPSec AH'
                58 = 'ICMP-IPv6'
                66 = 'MIT Remote Virtual Disk (RVD)'
                88 = 'IGMP'
                89 = 'OSPF'
            }
        #endregion

        #region Get values from Events and add custom additional properties
            $objects = $xmlEventsFound.Events.Event |
                ForEach-Object{
	                #region Create current hash table and add all properties from event
                        $currHash = @{}
	                    $_.EventData.Data | foreach {
                            if($_.Name -ne $null){
                                $currHash.Add($_.Name, $_.'#text')
                            }
                        }
                    #endregion
                    
                    #region Add Timestamp
                        $currHash.Add("Timestamp",$(Get-Date $_.System.TimeCreated.SystemTime))
                    #endregion

                    #region Add EventId and EventType
                        $currHash.Add("EventID",$_.System.EventID)

                        if($_.System.EventID -eq "5152"){$EventType = "DROP  - Packet dropped by WPF"}
                        elseif($_.System.EventID -eq "5153"){$EventType = "VETO  - Packet vetoed by WPF"}
                        elseif($_.System.EventID -eq "5154"){$EventType = "ALLOW - Listen permitted"}
                        elseif($_.System.EventID -eq "5155"){$EventType = "BLOCK - Listen blocked"}
                        elseif($_.System.EventID -eq "5156"){$EventType = "ALLOW - Connection permitted"}
                        elseif($_.System.EventID -eq "5157"){$EventType = "BLOCK - Connection blocked"}
                        elseif($_.System.EventID -eq "5158"){$EventType = "ALLOW - Bind permitted"}
                        elseif($_.System.EventID -eq "5159"){$EventType = "BLOCK - Bind blocked"}
                        else{$EventType = "Unknown"}
                        $currHash.Add("EventType",$EventType)
                    #endregion

                    #region Add ProcessInfo
                        $currprocessObj = Get-Process -Id $currHash.ProcessID -IncludeUserName -ErrorAction SilentlyContinue
	                    $currHash.Add("ProcessPath",$currprocessObj.Path)
                        $currHash.Add("ProcessUsername",$currprocessObj.UserName)
                    #endregion

                    #region Add Protocol name from ProtocolMapper
                        $ProtocolName = $ProtocolMapper.$([int]$currHash.Protocol)
                        $currHash.Add("ProtocolName",$ProtocolName)
                    #endregion

                    #region Add Rule info from $currentWinFWfiltersHash hash table
                        if($currHash.FilterRTID -eq 0){
                            $currHash.Add("Rule",$null)
                        }
                        else{
                            $currFilterObj = $currentWinFWfiltersHash.$($currHash.FilterRTID)
                            if($currFilterObj){ $currHash.Add("Rule",$currFilterObj) }
                            else{ $currHash.Add("Rule","NotFound") }
                        }
                    #endregion

                    #region Add Layer info
                        $currLayerObj = $currentWinFWstateHash.$($currHash.LayerRTID)
                        if($currLayerObj){ $currHash.Add("LayerInfo",$currLayerObj) }
                        else{ $currHash.Add("LayerInfo","NotFound") }
                    #endregion

                    #region Replace direction with friendly name value
                        if($currHash.Direction -match "14592"){$currHash.Direction = 'Inbound'}
                        elseif($currHash.Direction -match "14593"){$currHash.Direction = 'Outbound'}
                    #endregion

                    #region Add Destination Address Type
                        if($LocalAddresses.Keys -contains $currHash.SourceAddress){ $currHash.Add("SourceType",$LocalAddresses.$($currHash.SourceAddress)) }
                        else{ $currHash.Add("SourceType",$null) }
                    #endregion

                    #region Add Destination Address Type
                        if($currHash.DestAddress -eq "239.255.255.250"){ $currHash.Add("DestType","UPnP/SSDP") }
                        if($currHash.DestAddress -eq "ff02::1"){ $currHash.Add("DestType","IPv6 Multicast") }
                        if($currHash.DestAddress -eq "ff02::1:2"){ $currHash.Add("DestType","IPv6 DHCP Multicast") }
                        if($currHash.DestAddress -eq "224.0.0.1"){ $currHash.Add("DestType","IPv4 Multicast") }
                        if($currHash.DestAddress -match ".255$"){ $currHash.Add("DestType","IPv4 Broadcast") }
                    #endregion

                    
                    #region Create PSObject with hash table
                        [PSCustomObject]$currHash
                    #endregion

                } | Select Timestamp,EventType,Direction,ProtocolName,SourceAddress,DestAddress,DestPort,SourceType,DestType,ProcessPath,ProcessUsername,Rule,LayerInfo,SourcePort,@{Name="ProtocolID";Expression={$_.Protocol}},Application,EventID
                #LayerName,RemoteMachineID,RemoteUserID,LayerRTID,FilterRTID,ProcessId
        #endregion

        #POST Steps

        #region Skip ICMP
            if($SkipICMP){ $objects = $objects | Where {$_.ProtocolName -notmatch "ICMP"} }
        #endregion

        #region Skip Web browsers
            if($SkipWebBrowsers){ $objects = $objects | Where {$_.ProcessPath -notmatch "msedge.exe$"} }
            if($SkipWebBrowsers){ $objects = $objects | Where {$_.ProcessPath -notmatch "firefox.exe$"} }
            if($SkipWebBrowsers){ $objects = $objects | Where {$_.ProcessPath -notmatch "chrome.exe$"} }
            if($SkipWebBrowsers){ $objects = $objects | Where {$_.ProcessPath -notmatch "iexplore.exe$"} }
        #endregion

        #region Filter Direction
            if($Direction -eq "Inbound"){ $objects = $objects | Where {$_.Direction -eq "Inbound"} }
            if($Direction -eq "Outbound"){ $objects = $objects | Where {$_.Direction -eq "Outbound"} }
        #endregion

        #region Skip Multicast and Broadcasts
            if($SkipBroadCastMultiCastAndSSDP){ $objects = $objects | Where {$_.DestType -notmatch "Broadcast|Multicast|SSDP"} }
        #endregion

        #region Skip IP-HTTPS Platform Interface events
            if($SkipIPHTTPSInterface){ $objects = $objects | Where {$_.SourceType -notmatch "IP-HTTPS Platform"} }
        #endregion

        $objects
    }
    else{
        Write-Verbose "No Events found matching the criteria" -Verbose
    }
}

Function Set-WFPLogging{
    <# 
    .SYNOPSIS
        Enables/disables "Filtering Platform Packet Drop" and "Filtering Platform Connection" audit logging to troubleshoot the Windows Firewall
    .DESCRIPTION
        Enables/disables the subcategory audit logging for "Filtering Platform Packet Drop" and "Filtering Platform Connection" from the Auditing Category "Object Access category"
        Does this by running auditpol with parameters. These audit settings can also be done from secpol.msc or GPO (but is not as easy).
        Enabling audit logs may drown you in Event Log data, so remember to disable the loggin when troubleshooting is done.
        For more information:
            https://docs.microsoft.com/en-us/windows/win32/fwp/auditing-and-logging
            https://docs.microsoft.com/en-us/previous-versions/windows/desktop/ics/troubleshooting-firewall-related-issues
    .PARAMETER Success
        Bool value for success auditing
    .PARAMETER Failure
        Bool value for failure auditing
    .NOTES
        AUTHOR: Micke Sundqvist
        LASTEDIT: 2020-04-13
        VERSION: 1.0
        CHANGELOG: 1.0 - Initial Release
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][bool]$Success,
        [Parameter(Mandatory=$true)][bool]$Failure
    )
    #Enabling audit logs may drown you in Event Log data, enabling only failure audits, and possibly only connection failures will reduce the number of log entries. Be selective about what you actually need

    if($Success){$SuccessValue = "enable"}else{$SuccessValue = "disable"}
    if($Failure){$FailureValue = "enable"}else{$FailureValue = "disable"}

    if($SuccessValue -eq "enable" -or $FailureValue -eq "enable"){
        Write-Warning -Message "Don't forget to turn off the audit when you are done."
        Write-Warning -Message "Enabling audit logs may drown you in Event Log data, enabling only failure audits, and possibly only connection failures will reduce the number of log entries. Be selective about what you actually need"
    }

    #https://docs.microsoft.com/en-us/windows/win32/fwp/auditing-and-logging

    #Auditing subcategory: Filtering Platform Packet Drop (Ignorera paket för filterplattform)
    $WFPPacketDropOutput = Invoke-Command -ScriptBlock { auditpol /set /subcategory:'{0CCE9225-69AE-11D9-BED3-505054503030}' /success:$SuccessValue /failure:$FailureValue }    
    if($WFPPacketDropOutput -match "The command was successfully executed"){ Write-Verbose -Message "Successfully updated: Success: `"$SuccessValue`" and Failure: `"$FailureValue`"" }
    
    #Auditing subcategory: Filtering Platform Connection (Anslutning för filterplattform)
    $WFPConnectionOutput = Invoke-Command -ScriptBlock { auditpol /set /subcategory:'{0CCE9226-69AE-11D9-BED3-505054503030}' /success:$SuccessValue /failure:$FailureValue }
    if($WFPConnectionOutput -match "The command was successfully executed"){ Write-Verbose -Message "Successfully updated: Success: `"$SuccessValue`" and Failure: `"$FailureValue`"" }

    if(
        (Invoke-Command -ScriptBlock { auditpol /get /subcategory:'{0CCE9225-69AE-11D9-BED3-505054503030}' /r } | Where {$_ -match $env:COMPUTERNAME}) -match "No Auditing" -and
        (Invoke-Command -ScriptBlock { auditpol /get /subcategory:'{0CCE9226-69AE-11D9-BED3-505054503030}' /r } | Where {$_ -match $env:COMPUTERNAME}) -match "No Auditing"
    ){
        Write-Verbose "Audit logging for `"Filtering Platform Packet Drop`" and `"Filtering Platform Connection`" successfully disabled"
    }

}
Function Disable-WFPLogging{
    <# 
    .SYNOPSIS
        Disables "Filtering Platform Packet Drop" and "Filtering Platform Connection" audit logging
    .DESCRIPTION
        This function disables audit logging or subcategories "Filtering Platform Packet Drop" and "Filtering Platform Connection".
        Can also be done with Set-WFPLogging, but this is faster
        For more information:
            https://docs.microsoft.com/en-us/windows/win32/fwp/auditing-and-logging
            https://docs.microsoft.com/en-us/previous-versions/windows/desktop/ics/troubleshooting-firewall-related-issues
    .NOTES
        AUTHOR: Micke Sundqvist
        LASTEDIT: 2020-04-13
        VERSION: 1.0
        CHANGELOG: 1.0 - Initial Release
    #>
    [CmdletBinding()]
    param()

    #Auditing subcategory: Filtering Platform Packet Drop (Ignorera paket för filterplattform)
    $WFPPacketDropOutput = Invoke-Command -ScriptBlock { auditpol /set /subcategory:'{0CCE9225-69AE-11D9-BED3-505054503030}' /success:disable /failure:disable }    
    
    #Auditing subcategory: Filtering Platform Connection (Anslutning för filterplattform)
    $WFPConnectionOutput = Invoke-Command -ScriptBlock { auditpol /set /subcategory:'{0CCE9226-69AE-11D9-BED3-505054503030}' /success:disable /failure:disable }

    if(
        (Invoke-Command -ScriptBlock { auditpol /get /subcategory:'{0CCE9225-69AE-11D9-BED3-505054503030}' /r } | Where {$_ -match $env:COMPUTERNAME}) -match "No Auditing" -and
        (Invoke-Command -ScriptBlock { auditpol /get /subcategory:'{0CCE9226-69AE-11D9-BED3-505054503030}' /r } | Where {$_ -match $env:COMPUTERNAME}) -match "No Auditing"
    ){
        Write-Verbose "Audit logging for `"Filtering Platform Packet Drop`" and `"Filtering Platform Connection`" successfully disabled"
    }

}
