# Script uses Sysinternals Disk Usage : https://learn.microsoft.com/en-us/sysinternals/downloads/du 
# This is to avoid hitting the upper limit of 256 characters in paths. Works fine when testing it.

Function Get-FolderSize{
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
        Write-Verbose -Message $ElapsedString

        $sizeondisk = $results | Select-String "Size on disk"
        $filesfound = $results | Select-String "Files:"
        
        $ErrorActionPreference = $currEAPref
    }
    catch{}

    if($sizeondisk -match "Size on disk:\s(.*)\sbytes"){
        $thebytes = $Matches.1 -replace "\s",""
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
        }
    }
}
