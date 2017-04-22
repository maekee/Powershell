Function Remove-ResourceFromCollection{
<# 
.SYNOPSIS
    Removes a SCCM resource (device or user) from a SCCM collection

.DESCRIPTION
    The script removes a direct membership rule from selected collection. If the resource is a member based on any other criteria e.g
    query rule the resource cannot be removed with this script. Both device and user direct rules can be removed.

.PARAMETER ActionAccountUserName
    Username of the account performing the action

.PARAMETER ActionAccountPassword
    Password for the account performing the action

.PARAMETER SCCMServer 
    The SCCM server the script will connect to and run the WMI queries

.PARAMETER SCCMSiteCode 
    SCCM Site Code (three character value).

.PARAMETER Resource 
    The SCCM resource (device/computer) the direct membership rule is based on.
    Supported formats are:
    Computer formats:
    * Computername
    * Domainname\Computername
    User formats:
    * Username (SamAccountName
    * Down-level logon name (domainname\username)
    * UPN (username@domainName) or mail.

.PARAMETER Collection
    The target SCCM collection to remove the direct membership rule from.
    Both CollectionID and Collection name can be used on this parameter.

.PARAMETER IncludeUpdateCollectionMembership
    This is a True/False value if the collection should run an update collection
    membership after the SCCM resource is removed.

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
            if($CollObj.Count -eq 1){
                $CollObj = $CollObj[0]
                if($CollObj.CollectionType -eq 1){ Write-Verbose "Found user collection $($CollObj.Name)" }
                else{ Write-Verbose "Found device collection $($CollObj.Name)" }
            }
        }
        catch{ Write-Error "Error occurred when getting SCCM user Collection ($Collection). Exception: $($_.Exception.Message)" }
    #endregion

    #region Validate SCCM resource
        if($CollObj.Name -ne $null){
            try{
                #Firsts checks if the resource is a device (computer)
                if($Resource.Contains('\')){
                    $DomainPart = $Resource.Split('\')[0]
                    $ComputerNamePart = $Resource.Split('\')[1]
                    $ResObj = @(Get-WmiObject -Class SMS_R_SYSTEM -Filter "Name = '$ComputerNamePart' AND ResourceDomainORWorkgroup = '$DomainPart' AND Client = '1'" @extragwmiParameters)
                }
                else{ $ResObj = @(Get-WmiObject -Class SMS_R_SYSTEM -Filter "Name = '$Resource' AND Client = '1'" @extragwmiParameters) }

                if($ResObj.Count -gt 1){ Write-Warning "More than one device/computer with name $Resource found (with Client = 1)";break }
        
                #If found, validates what collection type was detected, and based on that if script will continue to search users or not
                if($ResObj.Count -eq 1 -and $CollObj.CollectionType -eq 2){ $ResObj = $ResObj[0]; Write-Verbose "Found computer $($ResObj.Name) with resource id $($ResObj.ResourceId)" }
                if($ResObj.Count -eq 1 -and $CollObj.CollectionType -eq 1){
                    Write-Warning "Found SCCM device/computer $($ResObj[0].Name). But because collection $($CollObj.Name) is a user collection, device can not be added and search will continue for user objects"
                    $ResObj = @()
                }

                #Continues to check if the resource is a SCCM user

                #Checks the format of the user name. Supported formats: username, down-level logon name (domainname\username), UPN (username@domainName) or mail.
                if($Resource.Contains('@')){ $SCCMAttribute = "UserPrincipalName" }
                elseif($Resource.Contains('\')){
                    #Backslash in WMI is an escape character, needs to add one more
                    $SCCMAttribute = "UniqueUserName" ; $ResourceWithBackslack = $Resource.Replace("\","\\")
                }
                else{ $SCCMAttribute = "UserName" }

                #Tries to automatically find the SCCM user based on resource format
                if($ResObj.Count -eq 0){
                    if($Resource.Contains('\')){ $ResObj = @(Get-WmiObject -Class SMS_R_User -Filter "$SCCMAttribute = '$ResourceWithBackslack'" @extragwmiParameters) }
                    else{ $ResObj = @(Get-WmiObject -Class SMS_R_User -Filter "$SCCMAttribute = '$Resource'" @extragwmiParameters) }
                }

                #If nothing is found and UserPrincipalName was used, it could also be mail.. search on attribute mail
                if($ResObj.Count -eq 0 -AND $SCCMAttribute -eq "UserPrincipalName"){ $ResObj = @(Get-WmiObject -Class SMS_R_User -Filter "mail = '$Resource'" @extragwmiParameters) }

                if($ResObj.Count -eq 0){ Write-Warning "No user where $SCCMAttribute is $Resource was found";break }
                if($ResObj.Count -gt 1){ Write-Warning "More than one user with attribute $SCCMAttribute was found";break }

                if($ResObj.Count -eq 1){ $ResObj = $ResObj[0];Write-Verbose "Found user $($ResObj.Name) with resource id $($ResObj.ResourceId)" }

            }
            catch{ Write-Error "Error occurred when getting SCCM resource ($Resource). Exception: $($_.Exception.Message)" }
        }
    #endregion

    #region Removing resource from collection based on resourcetype
        if($CollObj.Name -ne $null -and $ResObj.Name -ne $null){
            if($CollObj.CollectionType -eq 2 -and $ResObj.ResourceType -eq 5){
                #Applies to Computer/Device
                try{
                    $CollRule = (Get-WmiObject -List -Class SMS_CollectionRuleDirect @extragwmiParameters).CreateInstance()
                    $CollRule.ResourceClassName = "SMS_R_System"
                    $CollRule.ResourceID = $ResObj.ResourceId
                    $CollRule.Rulename = $ResObj.Name
                    $CollObj.DeleteMemberShipRule($CollRule) | Out-Null
                    if($IncludeUpdateCollectionMembership){ $CollObj.RequestRefresh() | Out-Null }
                    Write-Verbose "Removed computer $($ResObj.Name) from collection $($CollObj.Name)"
                }
                catch{ Write-Error "Error occurred when removing $Resource from collection $Collection. Exception: $($_.Exception.Message)" }
            }     
            if($CollObj.CollectionType -eq 1 -and $ResObj.ResourceType -eq 4){
                #Applies to User
                try{
                    $CollRule = (Get-WmiObject -List -Class SMS_CollectionRuleDirect @extragwmiParameters).CreateInstance()
                    $CollRule.ResourceClassName = "SMS_R_User"
                    $CollRule.ResourceID = $ResObj.ResourceId
                    $CollRule.Rulename = $ResObj.Name
                    $CollObj.DeleteMemberShipRule($CollRule) | Out-Null
                    if($IncludeUpdateCollectionMembership){ $CollObj.RequestRefresh() | Out-Null }
                    Write-Verbose "Removed user $($ResObj.Name) from collection $($CollObj.Name)"
                }
                catch{ Write-Error "Error occurred when removing $Resource from collection $Collection. Exception: $($_.Exception.Message)" }
            }
        }
    #endregion
}