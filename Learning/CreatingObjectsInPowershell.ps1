### Different ways to create a Objects in PowerShell

## Creating objects with the help of a hash table arrived in PowerShell v2.
## Creating objects of type PSCustomObject (Fullname [System.Management.Automation.PSCustomObject]) arrived in PowerShell v3, before v3, we used PSObject instead.
## Hash tables got the [ordered] functionality in PowerShell v3 (DotNET Full typename: [System.Collections.Specialized.OrderedDictionary])
## (Hash table DotNET Full typename: [System.Collections.Hashtable])

#region New-Object: Type PSObject and properties with the help of Add-Member (Pre PowerShell v3 Compatible / Old School)
  $Obj = New-Object -TypeName PSObject
  $Obj | Add-Member -Membertype NoteProperty -Name "ComputerName" -Value $env:COMPUTERNAME
  $Obj | Add-Member -Membertype NoteProperty -Name "ComputerModel" -Value (gwmi win32_computersystem).Model
#endregion

#region New-Object: Type PSObject and properties from a pre-created hash table ([Ordered] came in v3 and is optional)
  $propHash = [Ordered]@{}
  
  $propHash.'ComputerName' = $env:COMPUTERNAME
  $propHash.'ComputerModel' = (gwmi win32_computersystem).Model
  $propHash.'LastBootUpTime' = Get-Date ([Management.ManagementDateTimeConverter]::ToDateTime( (Get-WmiObject Win32_Operatingsystem).LastBootUpTime )) -format "yyyy-MM-dd HH:mm"
  $propHash.'Logged-on User' = $env:USERNAME
  $propHash.'ConnectedDomainController' = $env:LOGONSERVER.Substring(2)
  
  $NewObject = New-Object PSObject -Property $propHash
#endregion

#region New-Object: Type PSObject and properties from a hash table on the fly
  $CustomObject1 = New-Object PSObject -Property @{ComputerName = $env:COMPUTERNAME;ComputerModel = (gwmi win32_computersystem).Model;ConnectedDomainController = $env:LOGONSERVER.Substring(2)}
#endregion

#region With PSCustomObject type adapter (Arrived in PowerShell v3)
#Creating Arrays with the help of this Type adapter gives a massive performance increase (5-30x) compared to New-Object cmdlet
#Behind the scenes, PowerShell creates a [ordered] hash table and wraps it a PSCustomObject.
  $NewObject = [PSCustomObject]@{
      ComputerName = $env:COMPUTERNAME
      ComputerModel = (gwmi win32_computersystem).Model
      'Logged-on User' = $env:USERNAME
      MyGitHub = 'https://github.com/maekee'
  }

#Maybe you want to add a cool method to this Object or another property.
#Add the VisitWebSite method like this:
$NewObject | Add-Member -MemberType ScriptMethod -Name VisitWebSite -Value { Start-Process -FilePath $this.MyGitHub }
#Then just call the method with:
$NewObject.VisitWebSite()

#Maybe you want another property, easy.. just like this:
$NewObject | Add-Member -MemberType NoteProperty -Name DomainName -Value $($env:USERDOMAIN)

#endregion

#region Creating a custom object with Select-Object
#Handy trick from back in the PowerShell v1 days.
  $NewObject = "" | Select Name,ID
  $NewObject.Name = "Maekee"
  $NewObject.ID = 1
#endregion
