# Script uses Sysinternals Disk Usage : https://learn.microsoft.com/en-us/sysinternals/downloads/du 
# This is to avoid hitting the upper limit of 256 characters in paths. Works fine when testing it.
# Different output from PowerShell and PowerShell ISE, tried to fix that in output.

Function Get-FolderSize{
<#
    .SYNOPSIS
    Gets size of folder with the help of Sysinternals Disk Usage : https://learn.microsoft.com/en-us/sysinternals/downloads/du
    This is to get around .NET 255 character path limit.

    .DESCRIPTION
    Creates a Microsoft Event Trace log file (etl) for the duration of the time specified in the parameter CaptureSeconds.
    The function is "just" a wrapper where the star of the show is "netsh trace", but added additional flexibility of PowerShell

    .PARAMETER DUPath
    Parameter to specify how long the trace should last

    .PARAMETER FolderPath
    Parameter to specify IP address of the interface to capture from

    .EXAMPLE
    Get-FolderSize -DUPath c:\DU\Du64.exe -FolderPath D:\Data
    Gets size of D:\Data

    .NOTES
    Calling 3rd party programs like du.exe acts different in PowerShell ISE and Powershell, thats why we remove all non-digits from output from DU.
    
    Author:      @mickesunkan
    Github:      https://github.com/maekee/Powershell
    Version:     v1.0 (2024-07-05)
    #>
    [CmdletBinding()]
    param(
        [ValidateScript({ if(Test-Path -Path $_){$true}else{throw "$_ not found"}})][string]$DUPath,
        [ValidateScript({ if(Test-Path -Path $_){$true}else{throw "$_ not found"}})][string]$FolderPath
    )

    $FolderName = Split-Path $FolderPath -Leaf

    try{
        $currEAPref = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"
        
        Write-Verbose -Message "Getting size of $FolderName..."
        $DUTime = Measure-Command {$results = & $($DUPath) $FolderPath -nobanner -accepteula }
        $ElapsedString = "Elapsed time: {0} days, {1} hours, {2} minutes, {3} seconds " -f [math]::round($DUTime.Days), [math]::round($DUTime.Hours), [math]::round($DUTime.Minutes), [math]::round($DUTime.Seconds)
        
        #region Logging
            if($DUTime.Days -eq 0 -and $DUTime.Hours -eq 0 -and $DUTime.Minutes -eq 0 -and $DUTime.Seconds -lt 5){
                Write-Verbose -Message "Elapsed time: In a flash"
            }
            else{
                Write-Verbose -Message $ElapsedString
            }
        #endregion

        $sizeondisk = $results | Select-String "Size on disk"
        $filesfound = $results | Select-String "Files:"
        
        $ErrorActionPreference = $currEAPref
    }
    catch{}

    if($sizeondisk -match "Size on disk:\s(.*)\sbytes"){
        $thebytes = $Matches.1 -replace "\D","" #Removes non-digits
        if($Matches.1){
            $mbbytes = $thebytes/1mb;$mbbytes = [system.double]$mbbytes
            $gbytes = $mbbytes/1024;$gbytes = [System.double]$gbytes
            
            [PSCustomObject]@{
                FolderName = $FolderName
                FolderPath = $FolderPath
                Files = if($filesfound -match "Files:\s+(\d+)"){[int]$Matches.1}else{$null}
                MBSizeOnDisk = [math]::round($mbbytes,2)
                GBSizeOnDisk = [math]::round($gbytes,2)
                OrginalBytes = $thebytes
            }

            Write-Verbose -Message "SizeGB: $([math]::round($gbytes,2))"

        }

    }
}
