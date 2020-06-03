Function Get-ControlAccessRights {
    #https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-adts/1522b774-6464-41a3-87a5-1e5633c3fbbb
    [CmdletBinding()]
    param(
        [string]$Guid = '*',
        [string]$NameFilter = ""
    )
    $rootdse = Get-ADRootDSE
    Get-ADObject -SearchBase ($rootdse.ConfigurationNamingContext) -LDAPFilter "(&(objectclass=controlAccessRight)(rightsguid=$Guid))" -Properties DisplayName,rightsGuid | Sort DisplayName | Foreach {
        if($_.DisplayName -match $NameFilter){ New-Object PSObject -Property @{Name = $_.DisplayName;ACEGuid = $_.rightsGuid} }
    }
}
