#region Collect SchemaGUIDs
    $ObjectTypeHash = @{}

    Function Add-ObjToHash {
        param($TheGUID,$FullObject)

        if($ObjectTypeHash.Keys -contains $TheGUID){ $FullObject }
        else{ [void]$ObjectTypeHash.Add($TheGUID,$FullObject) }
    }

    # Get All Attribute Schema Objects (like givenName, userPrincipalName, etc.)
    Get-ADObject -SearchBase ((Get-ADRootDSE).schemaNamingContext) `
                 -LDAPFilter "(objectClass=attributeSchema)" `
                 -Properties lDAPDisplayName,schemaIDGUID | 
        Select-Object DistinguishedName,lDAPDisplayName,Name,ObjectClass,ObjectGUID, @{Name="schemaIDGUID"; Expression={[System.GUID]::new($_.schemaIDGUID)}} | `
        ForEach-Object { Add-ObjToHash -TheGUID $_.schemaIDGUID.Guid -FullObject $_ }

    # Get All Schema Classes (User, Group, Computer, etc.)
    Get-ADObject -SearchBase ((Get-ADRootDSE).schemaNamingContext) `
                 -LDAPFilter "(objectClass=classSchema)" `
                 -Properties lDAPDisplayName, schemaIDGUID |
        Select-Object DistinguishedName,lDAPDisplayName,Name,ObjectClass,ObjectGUID, @{Name="schemaIDGUID"; Expression={[System.GUID]::new($_.schemaIDGUID)}} | `
        ForEach-Object { Add-ObjToHash -TheGUID $_.schemaIDGUID.Guid -FullObject $_ }


    # Get All Extended Rights (control rights like Change Password, Reset Password, etc.)
    Get-ADObject -SearchBase "CN=Extended-Rights,CN=Configuration,$((Get-ADRootDSE).rootDomainNamingContext)" `
                 -LDAPFilter "(objectClass=controlAccessRight)" `
                 -Properties displayName, rightsGuid | 
        Select-Object DisplayName,DistinguishedName,Name,ObjectClass,ObjectGUID, rightsGuid | `
        ForEach-Object { Add-ObjToHash -TheGUID $_.ObjectGUID.Guid -FullObject $_ }

#endregion

# We can now translate ADDS ObjectType GUIDS with $ObjectTypeHash."GUIDHERE".Name

# Example
(Get-ACL 'AD:\OU=CompanyComputers,DC=domain,DC=com').Access | `
    Select   AccessControlType,
             IdentityReference,
             @{Name="ObjectTypeName";Expression={ $ObjectTypeHash.$($_.ObjectType.Guid).Name }},
             PropagationFlags,
             IsInherited,
             InheritanceType,
             @{Name="InheritedObjectTypeName";Expression={ $ObjectTypeHash.$($_.InheritedObjectType.Guid).Name }}
