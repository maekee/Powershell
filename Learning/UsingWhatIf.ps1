#The WhatIf parameter can be initiated by adding [CmdletBinding()], but if you want to use it you need to use [CmdletBinding(SupportsShouldProcess=$true)]
#This will enable you to add the method ShouldProcess which tells you what to run if WhatIf is NOT used.

#Example 1:
Function Set-Action {
  [CmdletBinding(SupportsShouldProcess=$true)]
  param ($Object1)
  if ($pscmdlet.ShouldProcess($Object1)){
    "Setting Action on $Object1"
  }
}

#By running this, like this: Set-Action -Object1 myObj
#returns: Setting Action on myObj
#Using What if, Set-Action -Object1 myObj -WhatIf
#returns: What If: Performing the operation "Set-Action" on target "myObj".

#You can also specify what action you want to include in the message by using two arguments when calling the ShouldProcess method:

#Example 2:
Function Set-Action {
  [CmdletBinding(SupportsShouldProcess=$true)
  param($Object1)
  if ($pscmdlet.ShouldProcess($Object1,"Setting")){
    "Setting Action on $Object1"
  }
}

#When executing the WhatIf parameter the resulting text will be:
#What If: Performing the operation "Setting" on target "myObj".

#So enjoy WhatIffing...
