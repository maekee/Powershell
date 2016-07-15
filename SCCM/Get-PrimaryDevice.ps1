## Simple Function go get primary device from SCCM via WMI

Function Get-PrimaryDevice {
    [CmdletBinding()]
    param (
        [string]$Username,
        [string]$SCCMSiteCode,
        [string]$SCCMSiteServer)

    TRY{$DataReturnedFromWMI = Get-WmiObject -Namespace "Root\SMS\Site_$SCCMSiteCode" -Class "SMS_UserMachineRelationship" -Filter "(UniqueUserName='$($env:USERDOMAIN)\\$Username')" -ComputerName $SCCMSiteServer -ErrorAction Stop }
    CATCH{ Write-Warning "Problem occurred while getting data from WMI. Exception: $($_.Exception.Message)" }

    $ReturnFromFunction = @($DataReturnedFromWMI | Where {$_.ResourceClientType -eq "1" -AND $_.IsActive -eq $true})
    IF($ReturnFromFunction.Count -eq 0){ Write-Verbose "No Primary devices detected";return $null }
    ELSE{
        $ReturnFromFunction | Select @{Name="PrimaryDevices";Expression={($_.ResourceName).ToUpper()}},@{Name="TimeStamp";Expression={ Get-Date ([Management.ManagementDateTimeConverter]::ToDateTime( $_.CreationTime )) -format "yyyy-MM-dd HH:mm" } }
    }
}

#Usage example: Get-PrimaryDevice -Username <username> -SCCMSiteCode CM1 -SCCMSiteServer SCCMServer01
