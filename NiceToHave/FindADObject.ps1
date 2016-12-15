function FindADObject{
<# 
.SYNOPSIS
    Searches in single/multi domain environments for users, groups and/or computers.

.DESCRIPTION
    The function uses the .NET directory DirectorySearcher class to find users, groups and computers in single or multidomain environments.
    Default is to search for users, groups and computers from top of current domain after the first 250 results.

.PARAMETER adObject 
    The name of the ad object (user,group,computer) to search for.
    Supported ad object formats are:
    * Username/SamAccountName
    * UPN (username@domainName)
    * DistinguishedName
    * Common Name
    * Down-level logon name (domainname\username)

.PARAMETER filterTypes 
    Defines what objects to search for, accepted values are user,group,computer in one (commaseparated) string e.g "user,computer" or "group,computer"
    If this parameter is not used or invalid value is supplied, FindADObject will search for "user,group,computer".

.PARAMETER multidomain
    This boolean parameter enables multi-domain support. Default value is $false (single domain)

.PARAMETER searchRoot
    This parameter specifies the scope of an Active Directory search. Recommended for performance is to specify an OU distinguishedname as close to
    the objects in active directory that is possible. Default is the current domain root.

.PARAMETER includeWildcards
    This boolean parameter enables wildcards on all values.

.PARAMETER limitResults
    Specifies how many search results to be returned. Recommended for performance is to specify this value as low as possible.

.PARAMETER useRootDomain
    This parameter can be used if the function is used in a child domain and it is desirable to search
    from the forest root domain.

.EXAMPLE
    Finds users,groups and computers with SamAccountName micsun
    FindADObject -adObject "micsun"

.EXAMPLE
    Finds users,groups and computers with UPN micsun@domain.local
    FindADObject -adObject "micsun@domain.local"

.EXAMPLE
    Finds all users,groups and computers that matches *mic*
    FindADObject -adObject "mic" -includeWildcards $true

.EXAMPLE
    Finds groups that matches *group* in OU OU=Groups,DC=domain,DC=local
    FindADObject -adObject "group" -includeWildcards $true -filterTypes "group" -searchRoot "OU=Groups,DC=domain,DC=local"

.EXAMPLE
    Finds all users that matches user00* in all domains from current and down and return the first 10
    FindADObject -adObject "user00*" -filterTypes "user" -multidomain $true -limitResults 10

.EXAMPLE
    Finds users with SamAccountName micsun in all domains and start the search from the forest root domain including child domains
    FindADObject -adObject "micsun" -multidomain $true -useRootDomain $true

.EXAMPLE
    Finds user micsun in domain playground
    FindADObject -adObject "ground\micsun" -useRootDomain $true

.NOTES
    AUTHOR: Micael Sundqvist
    LASTEDIT: 2016-12-14
    VERSION: 3.0
#>
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$adObject,
        [Parameter(Position=1)][string]$filterTypes,
        [boolean]$multidomain,
        [string]$searchRoot,
        [boolean]$includeWildcards,
        [int]$limitResults,
        [boolean]$useRootDomain = $false
    )

    #region Getting username part if format contains backslash
        $originaladObject = $adObject
        if($originaladObject.Contains("\")){ $adObject = $originaladObject.Split("\")[1] }
    #endregion

    #region Building custom filter based on filterTypes parameter
        #region Getting parameter values into array
        if([string]::IsNullOrEmpty($filterTypes)){
            $filterTypes = "user","computer","group" }
        else{
            if( @($filterTypes).Count -eq 1 ){
                [string[]]$filterTypes = $filterTypes
                if( $filterTypes[0].Contains(",") ){ $filterTypes = $filterTypes.Split(",") }
                else{ [string[]]$filterTypes = $filterTypes }
            }
        }
        #endregion

        #region Cleaning up allowed parameter values
        [System.Collections.ArrayList]$cleanfilterArray = @()
        foreach($filterItem in $filterTypes){
            #Add filter to cleanFilterArray if its user,computer and/or group and its not already in the array
            if(($filterItem.Trim() -eq "user" -or $filterItem.Trim() -eq "computer" -or $filterItem.Trim() -eq "group") -and $cleanfilterArray -notcontains $filterItem.Trim() ){
                $cleanfilterArray.Add( $filterItem.Trim() ) | Out-Null
            }
        }
        #endregion

        #region Adding user,computer and group if no allowed values is entered
        if($cleanfilterArray.Count -eq 0){
            Write-Verbose "No valid filter types found. Using user, group and computer"
            $cleanfilterArray.Add( "user" ) | Out-Null
            $cleanfilterArray.Add( "computer" ) | Out-Null
            $cleanfilterArray.Add( "group" ) | Out-Null
        }else{ Write-Verbose "Filtering by type $($cleanfilterArray -join ", ")" }
        #endregion

        #region Building filter string to be used by DirectorySearcher
        $filterStringValue = ""
        foreach($cleanItem in $cleanfilterArray){
            if($cleanItem -eq "user"){$filterStringValue += "(sAMAccountType=805306368)"}
            elseif($cleanItem -eq "computer"){$filterStringValue += "(objectCategory=computer)"}
            elseif($cleanItem -eq "group"){$filterStringValue += "(objectClass=group)"}
        }
        #endregion

        #region Adding wildcards if desired
            if($includeWildcards){ $wch = '*' }else{ $wch = '' }
            $strFilter = "( &(|(distinguishedName=$wch$adObject$wch)(sAMAccountName=$wch$adObject$wch)(cn=$wch$adObject$wch)(userPrincipalName=$wch$adObject$wch))(|$filterStringValue) )"
        #endregion

    #endregion

    #region Checking if root domain is used
        $domainDN = (New-Object System.DirectoryServices.DirectoryEntry).distinguishedName[0]
        $rootDomain = ([ADSI]"LDAP://RootDSE").rootDomainNamingContext[0]
        
        if($useRootDomain){
            $domainDN = $rootDomain
            
            #If domain is specified, the multidomain parameter needs to be enabled.
            #If not enabled and user is in another domain than current, object is not found
            if($originaladObject.Contains("\")){$multidomain = $true}
            
            Write-Verbose "Searching from $domainDN"
        }
        else{
            if($domainDN -ne $rootDomain){ Write-Verbose "You are now searching in $domainDN, which is not the root domain ($rootDomain)" }
        }

    #endregion

    #region Multidomain and Searchscope configuration
        if($multidomain){
            $ADSIScope = "GC"
            Write-Verbose "Multidomain search enabled, searching against Global Catalog"
        }
        else{
            $ADSIScope = "LDAP"
            Write-Verbose "Searching against current domain ($domainDN)"
        }

        #Validate that searchRoot exists as an or organizationalunit or domain
        if(![string]::IsNullOrEmpty($searchRoot)){
            #$seekOU = New-Object System.DirectoryServices.DirectorySearcher([ADSI]"$($ADSIScope)://$searchRoot")
            $seekOU = New-Object System.DirectoryServices.DirectorySearcher([ADSI]"$($ADSIScope)://$domainDN")
            $seekOU.Filter = "(&(distinguishedname=$searchRoot)(|(objectCategory=organizationalunit)(objectCategory=domainDNS)))"
            $seekOU.PageSize = 10
            $seekOU.SizeLimit = 10
            $seekOU.ServerTimeLimit = $([timespan]::FromSeconds(3.0))
            $seekOU.ClientTimeout = $([timespan]::FromSeconds(3.0))
            $seekOU.ServerPageTimeLimit = $([timespan]::FromSeconds(3.0))

            try{
                $OUStatus = $seekOU.FindOne()
                $OUStatus = $OUStatus | Where {$_.properties.distinguishedname -eq $searchRoot}
                if(![string]::IsNullOrEmpty($OUStatus)){ $domainDN = $searchRoot }else{ Write-Verbose "$searchRoot not found, using $domainDN" }
                Write-Verbose "Search scope targeted to to $domainDN"
            }
            catch{ Write-Host "$searchRoot not found, using $domainDN. Use multiDomain parameter if desired. Exception occurred: $($_.exception.message)" }
        }
    #endregion

    #region Defining limitResults parameter if not used
        if($limitResults -eq 0){$limitResults = 250}
        Write-Verbose "Maximum number of results are limited to $limitResults"
    #endregion

    #region Defining DirectorySearcher configuration
        $objSearcher = New-Object System.DirectoryServices.DirectorySearcher([ADSI]"$($ADSIScope)://$domainDN")
        $objSearcher.Filter = $strFilter
        $objSearcher.PageSize = 500
        $objSearcher.SizeLimit = $limitResults
        $objSearcher.SearchScope = "Subtree"

        #Defining what properties to get back, comment out the following two lines to get all properties
        $propertyList = "samaccountName","distinguishedName","displayname","name","objectsid"
        foreach ($currentProperty in $propertyList) { $objSearcher.PropertiesToLoad.Add($currentProperty) | Out-Null }
    #endregion

    #region Getting results and returning custom PSCustomObject
        $Results = $objSearcher.FindAll()

        if($Results.Count -ne 0){

            [System.Collections.ArrayList]$UsersinResults = @()
            foreach ($objResult in $Results) {

                #region Down-level logon name (domainname\username)
                try{
                    $objectSid = [byte[]]$($objResult.Properties.objectsid)
                    $sid = New-Object System.Security.Principal.SecurityIdentifier($objectSid,0)
                    $domainusernamevalue = ($sid.Translate([System.Security.Principal.NTAccount])).Value
                }
                catch{
                    Write-Verbose "Error occurred while getting down-level logon name (domainname\username). Exception: $($_.exception.message)"
                    $domainusernamevalue = $null
                }
                #endregion 

                $userObject = [PSCustomObject]@{
                    Name = $objResult.Properties.name[0]
                    DisplayName = "$($objResult.Properties.name[0]) ($domainusernamevalue)"
                    SamAccountName = $objResult.Properties.samaccountname[0]
                    DistinguishedName = $objResult.Properties.distinguishedname[0]
                    DomainUserName = $domainusernamevalue
                }
                
                #Adding only objects that match syntax if backslash is used, if not used add all objects found
                if($originaladObject.Contains("\")){
                    if($userObject.DomainUserName -eq $originaladObject){ $UsersinResults.Add($userObject) | Out-Null }
                }else{ $UsersinResults.Add($userObject) | Out-Null }
            
            }

            $UsersinResults

        }else{ Write-Host "No objects (of type $($cleanfilterArray -join ",")) found that matches `"$originaladObject`"" }
    #endregion
}