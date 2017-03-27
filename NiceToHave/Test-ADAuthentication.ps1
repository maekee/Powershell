#This function validates username and password, multidomain support. (Have tested in parent->childdomain scenario)
#Added RegEx så that only Domain\Username syntax (Downlevel domain-name) is supported.
#Function returns False both if user is not found and if password is incorrect.

Function Test-ADAuthentication {
  param($DomainBackslashUsername,$DaPass)
    if($DomainBackslashUsername | Select-String -AllMatches -Pattern '^[a-z0-9]{1,15}\\[\sa-z0-9._-]{1,104}$'){
      $DomainBackslashUsername = $DomainBackslashUsername.Trim()
      (New-Object System.DirectoryServices.DirectoryEntry "",$DomainBackslashUsername,$DaPass).psbase.name -ne $null
      }
    else{ Write-Warning "`'$DomainBackslashUsername`' not allowed syntax, should be DOMAIN\USERNAME" }
}