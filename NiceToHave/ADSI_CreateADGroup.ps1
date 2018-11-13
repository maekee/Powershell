#You can use this script to create AD groups where you dont have the AD module available.
#You have to modify it if you want to create distribution groups. If so, just remove the first 8 in the GroupHash values.
#If you want the params mandatory, thats also a simple fix.

Function Create-CustomADGroup{
	param(
		[string]$GroupName,
		[string]$OUPath,
		[ValidateSet('Global','DomainLocal','Universal')][string]$GroupType,
		[string]$Description
	)

	$GroupHash = @{
		Global      = 0x80000002
		DomainLocal = 0x80000004
		Universal   = 0x80000008
	}

	try{
		$TargetOU = [ADSI]"LDAP://$($OUPath)"
		$Group = $TargetOU.Create("Group","cn=$($GroupName)")
		$Group.put("grouptype",$($GroupHash.$GroupType))
		$Group.put("description", "$($Description)")
		$Group.put("sAMAccountName","$($GroupName)")
		$Group.SetInfo()
	}
	catch{
		Write-Warning "Error occurred while creating AD group `"CN=$GroupName,$OUPath`" (Type Security $GroupType, description `"$Description`". Exception: $($_.Exception.Message)"
	}
}
