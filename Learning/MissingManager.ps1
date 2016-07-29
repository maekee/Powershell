#Code Below queries Active Directory with a total of 14030 User Accounts
#See regions below for different ways to query users and find account with a missing manager property
#The filter property doesnt seem to work against the manager property, so i used ldapfilter instead

#region Getting all Users in AD where Manager is missing, using Where-Object:
    Measure-Command { Get-aduser -Filter * -Properties manager | Where {!($_.Manager)} }
    #Objects returned: 14030

    #Measure-Command results:
    #Days              : 0
    #Hours             : 0
    #Minutes           : 0
    #Seconds           : 17
#endregion

#region Getting all Users in AD where Manager is missing, using LDAPFilter - Manager missing:
Measure-Command { Get-ADUser -LDAPFilter {(!manager=*)} }
    #Objects returned: 12577

    #Measure-Command results:
    #Days              : 0
    #Hours             : 0
    #Minutes           : 0
    #Seconds           : 14
#endregion

#region Getting all Users in AD where Manager is missing, using LDAPFilter - Manager missing and only Active (enabled) accounts:
Measure-Command { Get-ADUser -LDAPFilter {(&(!manager=*)(!userAccountControl:1.2.840.113556.1.4.803:=2))} }
    #Objects returned: 8816

    #Measure-Command results:
    #Days              : 0
    #Hours             : 0
    #Minutes           : 0
    #Seconds           : 11
#endregion

#region Getting all Users in AD where Manager is missing, using LDAPFilter - Manager missing, and only Active (enabled) accounts scoped on the OU where i know the accounts are located
Measure-Command { Get-ADUser -LDAPFilter {(&(!manager=*)(!userAccountControl:1.2.840.113556.1.4.803:=2))} -SearchBase "OU=OnlyAccountsImInterestedIn,DC=domain,DC=com" }
    #Objects returned: 1264

    #Measure-Command results:
    #Days              : 0
    #Hours             : 0
    #Minutes           : 0
    #Seconds           : 2
    #Milliseconds      : 776
#endregion
