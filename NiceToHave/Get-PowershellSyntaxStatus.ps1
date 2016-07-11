Function Get-PowershellSyntaxStatus {
<#
.SYNOPSIS
Checks if a file has valid Powershell Code (Has no script errors)

.DESCRIPTION
Verifys if Path parameter file contains script errors. No errors returns $true and if script errors is present $false will be returned.

.PARAMETER Path
The File to be checked for script errors

.EXAMPLE
Get-PowershellSyntaxStatus -Path c:\temp\script.ps1
Get-PowershellSyntaxStatus c:\temp\script.ps1
"c:\temp\script.ps1" | Get-PowershellSyntaxStatus
dir c:\temp\script.ps1 | Get-PowershellSyntaxStatus

The four above examples does exactly the same

.NOTES 
Script name: Get-PowershellSyntaxStatus
Author:      Micke Sundqvist 
Twitter:     @mickesunkan 
Github:      https://github.com/maekee/Powershell 

#>
    [CmdletBinding()]
    param ( [Parameter(Mandatory = $true, ValueFromPipeline = $true)][string]$Path )
    PROCESS{
        $Content = Get-Content $Path
        IF($Content -eq $null){ Write-Warning "No content found";Break }

        $errors = $null
        $data = [System.Management.Automation.PSParser]::Tokenize($Content, [ref]$errors)
        
        IF($errors.Count -eq 0){ return $true }
        ELSE{ return $false }
    }
}
