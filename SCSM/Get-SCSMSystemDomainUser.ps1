Import-Module SMLets

#$smdefaultcomputer = "<Your SCSM Management Server>"

Function Get-SCSMSystemDomainUser{
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$UserNameID,
        [Parameter(Mandatory=$false, Position=1)][ValidateSet('UserName','UPN','DistinguishedName')][string]$Attribute = 'UPN',
        [Parameter(Mandatory=$false)][switch]$OnlyActive,
        [Parameter(Mandatory=$false)][switch]$OnlyWithUPN,
        [Parameter(Mandatory=$false)][switch]$OnlyWithFirstAndLastName
    )

    try{ $DomainUserClass = Get-SCSMClass -Name System.Domain.User$ -ErrorAction Stop }
    catch { Write-Error "Error occurred while getting System.Domain.User class. Exception: $($_.Exception.Message)" }

    try{
        $SystemDomainUsers = Get-SCSMObject -Class $DomainUserClass -ErrorAction Stop
        #Get-SCSMObject -Class $DomainUserClass | Select Domain,FirstName,LastName,UserName,UPN,DistinguishedName,ObjectStatus,TypeName,Name
    }
    catch{ Write-Error "Error occurred while getting users of class System.Domain.User. Exception: $($_.Exception.Message)" }

    if($SystemDomainUsers.count -gt 0){

        #Filters which users to search from later
        if($OnlyActive){ $SystemDomainUsers = @($SystemDomainUsers | Where {$_.ObjectStatus.Description -eq "System.ConfigItem.ObjectStatusEnum.Active"}) }
        if($OnlyWithUPN){ $SystemDomainUsers = @($SystemDomainUsers | Where {$_.Upn}) }
        if($OnlyWithFirstAndLastName){ $SystemDomainUsers = @($SystemDomainUsers | Where {$_.FirstName -and $_.Lastname}) }

        #Validates that not more than one user if found, and takes action depending on output
        $UserToReturn = @($SystemDomainUsers | Where {$_.$Attribute -eq $UserNameID})
        if($UserToReturn.Count -eq 1){$UserToReturn}
        elseif($UserToReturn.Count -gt 1){
            Write-Warning "$($UserToReturn.Count) users ($($UserToReturn.UPN -join ", ")) found with $Attribute $UserNameID, returning first entry"
            $UserToReturn[0]
        }
        elseif($UserToReturn.Count -eq 0){
            Write-Verbose "No users found with $Attribute $UserNameID, validate that custom filters dont remove to much"
            $null
        }
    }
    else{
        Write-Verbose "No objects returned from class System.Domain.User"
        $null
    }
}
