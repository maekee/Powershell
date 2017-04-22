Function Add-ResourceToCollection{
<# 
.SYNOPSIS
    Adds a computer (device) to a SCCM collection

.DESCRIPTION
    The script adds a direct membership rule to the collection.
    Dont forget to validate that the device you are trying to add is available based on the limiting collection.

.PARAMETER ActionAccountUserName
    Username of the account performing the action

.PARAMETER ActionAccountPassword
    Password for the account performing the action

.PARAMETER SCCMServer 
    The SCCM server the script will connect to and run the WMI queries

.PARAMETER SCCMSiteCode 
    SCCM Site Code (three character value).

.PARAMETER Resource 
    The SCCM resource (device/computer) name to base the direct membership rule on.
    Supported formats are:
    * Computername
    * Domainname\Computername

.PARAMETER Collection
    The target SCCM collection to create the new direct membership rule on.
    Both CollectionID and Collection name can be used on this parameter.

.PARAMETER IncludeUpdateCollectionMembership
    This is a True/False value if the collection should run an update collection
    membership after the SCCM device (machine) is added.

.NOTES
    AUTHOR: Micke Sundqvist
    LASTEDIT: 2017-03-08
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
        [Parameter(Mandatory=$true)][string]$Resource,
        [Parameter(Mandatory=$true)][string]$Collection,
        [Parameter(Mandatory=$false)][bool]$IncludeUpdateCollectionMembership
    )

    #region Declare Credentials, default parameters and variables
        $EncryptedActionAccountPassword = $SCCMPassword | ConvertTo-SecureString -AsPlainText -Force
        $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ActionAccountUserName,$EncryptedActionAccountPassword

        $extragwmiParameters = [ordered]@{
            "Namespace" = "Root\SMS\Site_$SCCMSiteCode"
            "ComputerName" = $SCCMServer
            "Credential" = $Credentials
            "ErrorAction" = 'Stop'
        }
    #endregion

    #region Validate Device Collection (first by ID then by Name)
        try{
            $CollObj = @(Get-WmiObject -Class SMS_Collection -Filter "CollectionID = '$Collection' AND CollectionType = 2" @extragwmiParameters)
            if($CollObj.Count -eq 0){ $CollObj = @(Get-WmiObject -Class SMS_Collection -Filter "Name = '$Collection' AND CollectionType = 2" @extragwmiParameters) }

            if($CollObj.Count -eq 0){ Write-Warning "Device collection $Collection not found";break }
            if($CollObj.Count -gt 1){ Write-Warning "More than one device collection with name $Collection found";break }
            if($CollObj.Count -eq 1){ $CollObj = $CollObj[0];Write-Host "Found device collection $($CollObj.Name)"}
        }
        catch{ Write-Error "Error occurred when getting SCCM device Collection ($Collection). Exception: $($_.Exception.Message)" }
    #endregion

    #region Validate SCCM resource
        try{
            #Checks if computername contains backslash (domainname\computername), then searches for computername AND domainname
            #and if no backslash is present, just search for the name.
            if($Resource.Contains('\')){
                $DomainPart = $Resource.Split('\')[0]
                $ComputerNamePart = $Resource.Split('\')[1]
                $ResObj = @(Get-WmiObject -Class SMS_R_SYSTEM -Filter "Name = '$ComputerNamePart' AND ResourceDomainORWorkgroup = '$DomainPart' AND Client = '1'" @extragwmiParameters)
            }
            else{ $ResObj = @(Get-WmiObject -Class SMS_R_SYSTEM -Filter "Name = '$Resource' AND Client = '1'" @extragwmiParameters) }

            if($ResObj.Count -gt 1){ Write-Warning "More than one device/computer found with name $Resource (where Client attribute = 1)";break }
            if($ResObj.Count -eq 1){ $ResObj = $ResObj[0]; Write-Host "Found computer $($ResObj.Name) with resource id $($ResObj.ResourceId)" }
        }
        catch{ Write-Error "Error occurred when getting SCCM resource ($Resource). Exception: $($_.Exception.Message)" }
    #endregion

    #region Add Device (computer) to collection
        if($ResObj -ne $null){
            try{
                $NewRule = (Get-WmiObject -List -Class SMS_CollectionRuleDirect @extragwmiParameters).CreateInstance()
                $NewRule.ResourceClassName = "SMS_R_System"
                $NewRule.ResourceID = $ResObj.ResourceID
                $NewRule.Rulename = $ResObj.Name
                $CollObj.AddMemberShipRule($NewRule) | Out-Null
                if($IncludeUpdateCollectionMembership){ $CollObj.RequestRefresh() | Out-Null }
                Write-Host "Added computer $($ResObj.Name) to collection $($CollObj.Name)"
            }
            catch{ Write-Error "Error occurred when adding $Resource to collection $Collection. Exception: $($_.Exception.Message)" }
        }
    #endregion
}
