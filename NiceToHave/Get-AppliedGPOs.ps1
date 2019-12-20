## This functions returns only applied user and computer GPOs in ascending order

Function Get-AppliedGPOs {
<# 
.SYNOPSIS
    Get list of Applied GPOs

.DESCRIPTION
    The script runs gpresult /R and parses out applied user and computer GPOs

.PARAMETER Name
    Optional Name parameter that supports regex

.NOTES
    AUTHOR: Micke Sundqvist
    LASTEDIT: 2019-12-20
    VERSION: 1.0
    CHANGELOG:    1.0 - Initial Release
#>
    param([string]$Name)
    
    $ArrayOutput = cmd /c gpresult /R
    $StringOutput = ""
    $ArrayOutput | Foreach { $StringOutput += "$_" + "`n" }

    $gpResultsPattern = 'Applied Group Policy Objects\n\s+-+\n(\s{8}.*\n)+'
    $gpresultResults = $StringOutput | Select-String $gpResultsPattern -AllMatches
    
    $AppliedGPOsRaw = @()
    $gpresultResults.Matches.Value | Foreach { ($_ -split "`n") | foreach { $AppliedGPOsRaw += $_ } }

    $AppliedGPOsClean = @($AppliedGPOsRaw | Where {
        $_ -notmatch "Applied Group Policy" -and
        $_ -notmatch "-----" -and
        $_ -notmatch "Lokal grupprincip" -and
        $_ -ne ""
    } | foreach {$_.Trim() } | Sort)

    if($PSBoundParameters.ContainsKey('Name')){
        $AppliedGPOsClean | Where {$_ -match $Name}
    }
    else{
        $AppliedGPOsClean
    }
}
