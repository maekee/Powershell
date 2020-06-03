#Got asked if i can write something that will show all AD user and OU owners. So i did. Enjoy!

Function Get-ADObjectOwner {
    param([Parameter(Mandatory=$true,Position=0)][string]$IdentityDN)
    $adObject = Get-ADObject -LDAPFilter "(distinguishedname=$IdentityDN)"
    (Get-Acl -Path ("ActiveDirectory:://RootDSE/$($adObject.distinguishedname)")).Owner
}
Function Set-ADObjectOwner{
    param(
        [Parameter(Mandatory=$true,Position=0)][string]$TargetObjectDN,
        [Parameter(Mandatory=$false,Position=1)][string]$OwnerIdentity = "S-1-5-21-686564821-1074279001-330569332-512" #Domain Admin SID
    )

    $targetObject = Get-ADObject -LDAPFilter "(|(distinguishedname=$TargetObjectDN)(objectsid=$TargetObjectDN))"
    $owneradObject = Get-ADObject -ldapfilter "(|(samaccountName=$OwnerIdentity)(objectsid=$OwnerIdentity)(distinguishedname=$OwnerIdentity))" -Properties samaccountname
    if($owneradObject -and $targetObject){
        $OwnerAce = New-Object System.Security.Principal.NTAccount($owneradObject.sAMAccountName)
        $ownerAceObj = Get-Acl -Path ("ActiveDirectory:://RootDSE/$($owneradObject.DistinguishedName)")
        $ownerAceObj.SetOwner($OwnerAce)

        try{ Set-Acl -Path ("ActiveDirectory:://RootDSE/$($targetObject.DistinguishedName)") -AclObject $ownerAceObj -ErrorAction Stop }
        catch{ Write-Warning "Error occurred while setting Owner to `"$($owneradObject)`" for object `"$($targetObject.distinguishedname)`". Exception: $($_.Exception.Message)" }
    }
    else{
        Write-Warning "OwnerIdentity (SamAccountName or SID) or TargetObjectDN (DistinguishedName) not found"
    }
}

$allADObjects = Get-ADObject -LDAPFilter "(|(samaccountType=805306368)(objectclass=organizationalUnit))"
$allADObjects = $allADObjects | Sort ObjectClass

$resultList = New-Object System.Collections.ArrayList

Foreach ($adObject in $allADObjects){
    
    $currentObjectACL = Get-Acl -Path ("ActiveDirectory:://RootDSE/$($adObject.DistinguishedName)")

    $currentObj = New-Object PSObject -Property @{
        "Class" = $adObject.ObjectClass
        "Name" = $adObject.Name
        "DistinguishedName" = $adObject.DistinguishedName
        "Owner" = $currentObjectACL.Owner
    }

    [void]$resultList.Add($currentObj)
}

$resultList | Select "Class","Name","DistinguishedName","Owner"
