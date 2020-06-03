#A little bit of code to add a computer/user to an AD group without the ActiveDirectory Module

Function Find-CustomADObject {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true,Position=0)][string]$Name)
    $search = New-Object System.DirectoryServices.DirectorySearcher("name=$($Name)")
    $result = $search.FindOne()
    if($null -eq $result){$null }
    else{ [ADSI]$result.Path }
}

$computerObject = Find-CustomADObject -Name $env:COMPUTERNAME
$groupObject = Find-CustomADObject -Name GroupNameHere

$groupObject.Add($computerObject.Path)
