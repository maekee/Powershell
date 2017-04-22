Function Add-UserToCollection{
<# 
.SYNOPSIS
    Adds a user to a SCCM collection

.DESCRIPTION
    The script adds a direct membership rule to the collection.
    Dont forget to validate that the user you are trying to add is available based on the limiting collection.

.PARAMETER ActionAccountUserName
    Username of the account performing the action

.PARAMETER ActionAccountPassword
    Password for the account performing the action

.PARAMETER SCCMServer 
    The SCCM server the script will connect to and run the WMI queries

.PARAMETER SCCMSiteCode 
    SCCM Site Code (three character value).

.PARAMETER Resource 
    The SCCM user to base the direct membership rule on.
    Supported formats are:
    * Username/SamAccountName
    * Down-level logon name (domainname\username)
    * UPN (username@domainName) or mail.

.PARAMETER Collection
    The target SCCM user collection to create the new direct membership rule on.
    Both CollectionID and Collection name can be used on this parameter.

.PARAMETER IncludeUpdateCollectionMembership
    This is a True/False value if the collection should run an update collection
    membership after the SCCM user is added.

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

    #region Validate User Collection (first by ID then by Name)
        try{
            $CollObj = @(Get-WmiObject -Class SMS_Collection -Filter "CollectionID = '$Collection' AND CollectionType = 1" @extragwmiParameters)
            if($CollObj.Count -eq 0){ $CollObj = @(Get-WmiObject -Class SMS_Collection -Filter "Name = '$Collection' AND CollectionType = 1" @extragwmiParameters) }

            if($CollObj.Count -eq 0){ Write-Warning "User collection $Collection not found";break }
            if($CollObj.Count -gt 1){ Write-Warning "More than one user collection with name $Collection found";break }
            if($CollObj.Count -eq 1){ $CollObj = $CollObj[0];Write-Verbose "Found user collection $($CollObj.Name)"}
        }
        catch{ Write-Error "Error occurred when getting SCCM user Collection ($Collection). Exception: $($_.Exception.Message)" }
    #endregion

    #region Validate SCCM resource
        #Checks the format of the user name. Supported formats: username, down-level logon name (domainname\username), UPN (username@domainName) or mail.
        if($Resource.Contains('@')){ $SCCMAttribute = "UserPrincipalName" }
        elseif($Resource.Contains('\')){
            #Backslash in WMI is an escape character, needs to add one more
            $SCCMAttribute = "UniqueUserName" ; $ResourceWithBackslack = $Resource.Replace("\","\\")
        }
        else{ $SCCMAttribute = "UserName" }

        try{
            #Search for users with autodetected attribute
            if($Resource.Contains('\')){ $ResObj = @(Get-WmiObject -Class SMS_R_User -Filter "$SCCMAttribute = '$ResourceWithBackslack'" @extragwmiParameters) }
            else{ $ResObj = @(Get-WmiObject -Class SMS_R_User -Filter "$SCCMAttribute = '$Resource'" @extragwmiParameters) }
            
            #If nothing is found and UserPrincipalName was used, it could also be mail.. search on attribute mail
            if($ResObj.Count -eq 0 -AND $SCCMAttribute -eq "UserPrincipalName"){ $ResObj = @(Get-WmiObject -Class SMS_R_User -Filter "mail = '$Resource'" @extragwmiParameters) }
            
            if($ResObj.Count -eq 0){ Write-Warning "No user where $SCCMAttribute is $Resource was found";break }
            if($ResObj.Count -gt 1){ Write-Warning "More than one user with attribute $SCCMAttribute was found";break }

            if($ResObj.Count -eq 1){ $ResObj = $ResObj[0];Write-Verbose "Found user $($ResObj.Name) with resource id $($ResObj.ResourceId)" }
        }
        catch{ Write-Error "Error occurred when getting SCCM user ($Resource). Exception: $($_.Exception.Message)" }
    #endregion

    #region Add user to collection
        if($ResObj -ne $null){
            try{
                $NewRule = (Get-WmiObject -List -Class SMS_CollectionRuleDirect @extragwmiParameters).CreateInstance()
                $NewRule.ResourceClassName = "SMS_R_User"
                $NewRule.ResourceID = $ResObj.ResourceID
                $NewRule.Rulename = $ResObj.Name
                $CollObj.AddMembershipRule($NewRule) | Out-Null
                if($IncludeUpdateCollectionMembership){ $CollObj.RequestRefresh() | Out-Null }
                Write-Verbose "Added user $($ResObj.Name) to collection $($CollObj.Name)"
            }
            catch{ Write-Error "Error occurred when adding $Resource to collection $Collection. Exception: $($_.Exception.Message)" }
        }
    #endregion
}