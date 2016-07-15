Function Set-FileDateProperty {
<#
.SYNOPSIS
    Sets new CreationTime, LastAccessTime or LastWriteTime on a file
.DESCRIPTION
    Sets a new CreationTime, LastAccessTime or LastWriteTime dateproperty on specified file in Path parameter.
.PARAMETER Path
    Path of File to be modified
.PARAMETER Property
    Select CreationTime, LastAccessTime or LastWriteTime as part of ValidateSet parameter
.PARAMETER NewTimeStamp
    Takes either DateTime variable or string formatted as "yyyy-MM-dd HH:mm"
.EXAMPLE
    Sets the CreationTime property to last year, on file c:\temp\NewFileWithOldTimeStamp.log. Include Verbose comments (as part of CmdletBinding)

    Set-FileDateProperty -Path c:\temp\NewFileWithOldTimeStamp.log -Property CreationTime -NewTimeStamp (Get-Date).AddYears(-1) -Verbose
.NOTES
    Script name: Set-FileDateProperty
    Author:      Micke Sundqvist
    Twitter:     @mickesunkan
    Github:      https://github.com/maekee/Powershell
#>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [ValidateSet('CreationTime','LastAccessTime','LastWriteTime')]
        [string]$Property,
        [string]$NewTimeStamp = (Get-Date)
   
    )

    $DateFormatCheck = TRY{ $(Get-Date $NewTimeStamp -ErrorAction Stop).GetType().FullName -eq 'System.DateTime' }CATCH{ $False}
    IF(!(Test-Path $Path)){ Write-Warning "$Path not found";Break }
    IF((Get-Item $Path).PSIsContainer){ Write-Warning "$Path is a folder, only files can be modified in this way";Break }
    IF(!($DateFormatCheck)){ Write-Warning "$NewTimeStamp not valid DateTime format";Break }

    Write-Verbose "Path: $Path"
    Write-Verbose "Property: $Property"
    Write-Verbose "NewTimeStamp: $(Get-Date -format "yyyy-MM-dd HH:mm")"

    TRY{ $tempvariable = (Get-Item $Path -ErrorAction Stop).$Property = $NewTimeStamp }
    CATCH{ "Setting $Property to $(Get-Date $NewTimeStamp -format "yyyy-MM-dd HH:mm") failed. Exception: $($_.Exception.Message)" }

    IF($tempvariable -ne $null){
        Write-Verbose "Successfully modified $Property to $(Get-Date $NewTimeStamp -format "yyyy-MM-dd HH:mm") on file $Path"
    }ELSE{
        Write-Warning "Houston we have a problem, doesn't seem that the new Datetime was set."
    }

}
