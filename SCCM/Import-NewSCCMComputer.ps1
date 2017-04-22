Import-NewSCCMComputer{
<# 
.SYNOPSIS
    Imports a new computer

.DESCRIPTION
    The script imports a new computer into SCCM based on Name and MAC address through WMI

.PARAMETER ActionAccountUserName
    Username of the account performing the action

.PARAMETER ActionAccountPassword
    Password for the account performing the action 

.PARAMETER SCCMServer 
    The SCCM server the script will connect to and run the WMI queries

.PARAMETER SCCMSiteCode 
    SCCM Site Code (three character value).

.PARAMETER ResourceName
    The name of the new resource to be imported

.PARAMETER ResourceMAC
    The hardware address (MAC address) of the new resource to be imported.
    The MAC address must be in colon format. For example, 00:00:00:00:00:00
    Other formats prevent the client from receiving policy

.NOTES
    AUTHOR: Snow Software
    LASTEDIT: 2017-03-07
    VERSION: 1.0
    PREREQUISITE: SCCM server WMI access permissions and enough SCCM permissions to modify requested collection memberships.
    CHANGELOG:    1.0 - Initial Release
#>
    param (
        [Parameter(Mandatory=$true)][string]$ActionAccountUserName,
        [Parameter(Mandatory=$true)][string]$ActionAccountPassword,
        [Parameter(Mandatory=$true)][string]$SCCMServer,
        [Parameter(Mandatory=$true)][string]$SCCMSiteCode,
        [Parameter(Mandatory=$true)][string]$ResourceName,
        [Parameter(Mandatory=$true)][string]$ResourceMAC
    )

    #region Declare Credentials, default parameters and variables
        $EncryptedActionAccountPassword = $ActionAccountPassword | ConvertTo-SecureString -AsPlainText -Force
        $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ActionAccountUserName,$EncryptedActionAccountPassword

        $extragwmiParameters = [ordered]@{
            "Namespace" = "Root\SMS\Site_$SCCMSiteCode"
            "Class" = "SMS_Site"
            "Name" = "ImportMachineEntry"
            "ComputerName" = $SCCMServer
            "Credential" = $Credentials
            "ErrorAction" = 'Stop'
        }
    #endregion

    #region Import the new computer
        try{
            Invoke-WmiMethod -ArgumentList @($null, $null, $null, $null, $null, $null, $ResourceMAC, $null, $ResourceName, $True, $null, $null) @extragwmiParameters
            Write-Verbose "Imported SCCM computer $($ResourceName) with MAC $($ResourceMAC)"
        }
        catch{ Write-Warning "Error occurred when importing new SCCM computer with name $($ResourceName) and MAC $($ResourceMAC). Exception: $($_.Exception.Message)" }
    #endregion
}