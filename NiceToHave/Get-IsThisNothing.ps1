Function Get-IsThisNothing {
	param ($Value)
	IF(([string]::IsNullOrEmpty($Value)) -OR ([string]::IsNullOrWhiteSpace($Value))){Return $True}ELSE{Return $False}
}
