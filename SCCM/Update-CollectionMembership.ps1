Update-CollectionMembership{
<# 
.SYNOPSIS
    Re-evaluates collection membership

.DESCRIPTION
    The script triggers an update collection membership on selected collection. This will ensure that the membership of the target collection
    is current before other activities are performed on the collection and its members.

.PARAMETER ActionAccountUserName
    Username of the account performing the action

.PARAMETER ActionAccountPassword
    Password for the account performing the action

.PARAMETER SCCMServer 
    The SCCM server the script will connect to and run the WMI queries

.PARAMETER SCCMSiteCode 
    SCCM Site Code (three character value).

.PARAMETER Collection
    The target SCCM collection (device collection or user collection) to initiate collection membership update on.
    Both CollectionID and Collection name can be used on this parameter. 

.NOTES
    AUTHOR: Snow Software
    LASTEDIT: 2017-03-07
    VERSION: 1.0
    PREREQUISITE: SCCM server WMI access permissions and enough SCCM permissions to modify requested collection memberships.
    CHANGELOG:    1.0 - Initial Release
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][string]$ActionAccountUserName,
        [Parameter(Mandatory=$true)][string]$ActionAccountPassword,
        [Parameter(Mandatory=$true)][string]$SCCMServer,
        [Parameter(Mandatory=$true)][string]$SCCMSiteCode,
        [Parameter(Mandatory=$true)][string]$Collection
    )

    #region Declare Credentials, default parameters and variables
        $EncryptedActionAccountPassword = $ActionAccountPassword | ConvertTo-SecureString -AsPlainText -Force
        $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ActionAccountUserName,$EncryptedActionAccountPassword

        $extragwmiParameters = [ordered]@{
            "Namespace" = "Root\SMS\Site_$SCCMSiteCode"
            "ComputerName" = $SCCMServer
            "Credential" = $Credentials
            "ErrorAction" = 'Stop'
        }
    #endregion

    #region Validate Collection (first by ID then by Name)
        try{
            $CollObj = @(Get-WmiObject -Class SMS_Collection -Filter "CollectionID = '$Collection'" @extragwmiParameters)
            if($CollObj.Count -eq 0){ $CollObj = @(Get-WmiObject -Class SMS_Collection -Filter "Name = '$Collection'" @extragwmiParameters) }

            if($CollObj.Count -eq 0){ Write-Warning "Collection $Collection not found";break }
            if($CollObj.Count -gt 1){ Write-Warning "More than one collection with name $Collection found, re-run and specify Collection ID instead";break }
            if($CollObj.Count -eq 1){ $CollObj = $CollObj[0] }
        }
        catch{ Write-Error "Error occurred when getting SCCM user Collection ($Collection). Exception: $($_.Exception.Message)" }
    #endregion

    #region Update the collection membership
        try{
            $CollObj.RequestRefresh() | Out-Null
            if($CollObj.CollectionType -eq 2){ write-verbose "Initiated update collection membership on $($CollObj.Name) (device collection)"}
            if($CollObj.CollectionType -eq 1){ write-verbose "Initiated update collection membership on $($CollObj.Name) (user collection)"}
        }
        catch{ Write-Error "Problems occurred while updating collection membership on $($CollObj.Name)" }
    #endregion
}