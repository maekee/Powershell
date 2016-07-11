Function Get-Length{
	[CmdletBinding()]
	param(
	  [ValidateLength(1,12)]
	  [string]$ComputerName
	)
	## ComputerName needs to be betweeen 1 and 12 characters
}

Function Get-Pattern{
	[CmdletBinding()]
	param(
	  [ValidatePattern('^(?!^(PRN|AUX|\..*')]
	  [string]$Value
	)
	## Needs to match RegEx pattern
}

Function Get-ValidateScript{
	[CmdletBinding()]
	param(
	[ValidateScript(
  	IF( $_ -notlike "tubb*){ $True }
  	ELSE{ Throw "$_ is not valid" }
	)]
	  [string]$ComputerName
	)
	## Nice replacement for RegEx with ability to create custom error messages
}

Function Get-Count{
	[CmdletBinding()]
	param(
	[ValidateCount(2,6)]
	  [string]$Value
	)
	## Only 2 OR 6 is allowed
}

Function Get-Range{
	[CmdletBinding()]
	param(
	[ValidateRange(5000,5010)]
	  [string]$Value
	)
	## Only values between 5000 and 5010
}

Function Get-Set{
	[CmdletBinding()]
	param(
	[ValidateSet('sweden'|'norway'|'denmark')]
	  [string]$Value
	)
	## only the three countries is allowed, Tab Completion works
}

Function Get-NotNullOrEmpty{
	[CmdletBinding()]
	param(
	[ValidateNotNullOrEmpty]
	[string]Value
	)
	## Null or Empty not allowed. Alternative is to use mandatory parameter
}

Function Get-Weekday{
  param([System.DayOfWeek]$Weekday)
  "You chose $Weekday"
}
