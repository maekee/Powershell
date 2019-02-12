## If you dont have time to backup and to mount ntds.dit to restore AD user attributes, AD groupmemberships and
## UAC-settings you can use these two small functions i have created. These will backup attributes specified in array below.
## An XML is created with the attributes. Then when using Restore-ADObjAttributes you get them back with the use of Set-ADUser
## and a bit of splatting. Members are managed separately because then cannot be added with Set-ADUser.

## I have looked in the Audit logs on the DC, and all attributes are updated (ofcourse).
## What can be improved in these functions are to be able to choose which attributes to restore and log before/after values.
## AD-groups will only be added when running Restore.. not removed if they are not there in the Backup XML.

## This can be used as a quick fix to get back attribute values that someone have accidently removed. Thing happen fast with PS :)

Function Backup-ADObjAttributes{
    [CmdletBinding()]
    param($SamAccountName,$Path)
    $PropertiesArray = @(
        "AccountNotDelegated",
        "AllowReversiblePasswordEncryption",
        "CannotChangePassword",
        "City",
        "Company",
        "Department",
        "Description",
        "DisplayName",
        "Fax",
        "GivenName",
        "EmailAddress",
        "Enabled",
        "Manager",
        "MemberOf",
        "MobilePhone",
        "Office",
        "OfficePhone",
        "PasswordNeverExpires",
        "PasswordNotRequired",
        "POBox",
        "PostalCode",
        "SamAccountName",
        "ScriptPath",
        "SmartcardLogonRequired",
        "StreetAddress",
        "Surname",
        "HomePhone",
        "Title"
    )
    $UserObj = Get-ADUser -LDAPFilter "(samAccountName=$SamAccountName)" -Properties $PropertiesArray | Select $PropertiesArray
    if($UserObj){
        $UserObj | Export-Clixml $Path -Depth 2 -Encoding UTF8 -Force
        Write-Verbose "Successfully backed up $($SamAccountName.ToLower()) to `"$Path`""
    }
    else{ Write-Warning "User $SamAccountName not found in $($env:USERDNSDOMAIN.ToLower())" }
}

Function Restore-ADObjAttributes{
    [CmdletBinding()]
    param($SamAccountName,$Path)

    $UserObj = Get-ADUser -LDAPFilter "(samAccountName=$SamAccountName)"
    if($UserObj){
        if(Test-Path $Path){
            $XMLFilePath = Get-ChildItem $Path
            try{ $XMLPSObj = Import-Clixml $XMLFilePath.FullName -ErrorAction Stop }
            catch { Write-Warning "Error occurred when trying to import/parse XML file `"$($XMLFilePath.FullName)`". Make sure the file is valid XML and try again. Exception: $($_.Exception.Message)" }
            if($XMLPSObj){
                if($XMLPSObj.SamAccountName -eq $UserObj.SamAccountName){
                    $SplattingObject = @{}
                    $XMLPSObj.psobject.properties | Where {$_.Name -notmatch "memberof"} | Foreach { $SplattingObject[$_.Name] = $_.Value }
                    try{
                        $UserObj | Set-ADUser @SplattingObject -ErrorAction Stop
                        Write-Verbose "Successfully updated $($UserObj.SamAccountName) with attribute values from `"$($XMLFilePath.FullName)`""
                        try{ $XMLPSObj.MemberOf | Foreach { Add-ADGroupMember -Identity $_ -Members $UserObj.SamAccountName } }
                        catch { Write-Warning "Error occurred while adding $($UserObj.SamAccountName) to $($(Foreach($Grp in $XMLPSObj.MemberOf){($Grp -split ",")[0] -replace 'CN=',''}) -join ', '). Exception: $($_.Exception.Message)" }
                    }
                    catch{
                        Write-Warning "Error occurred while updating user $($UserObj.SamAccountName) with attribute values from `"$($XMLFilePath.FullName)`". Exception: $($_.Exception.Message)"
                    }
                }
                else{ Write-Warning "Username $($XMLPSObj.SamAccountName) in XML file `"$($XMLFilePath.FullName)`" does not match target AD username $($UserObj.SamAccountName)" }
            }
        }
        else{ Write-Warning "`"$Path`" not found" }
    }
    else{ Write-Warning "User $SamAccountName not found in $($env:USERDNSDOMAIN.ToLower())" }
}
