Function Get-ParsedDefenderProcesses{
    param($LastRows = 1000)
    
    $DefenderLogPath = "C:\ProgramData\Microsoft\Windows Defender\Support\MPLog-*.log" #Microsoft Protection Log (MPLog)
    $regex = '^(?<Timestamp>\d{4}-\d{1,2}-\d{1,2}\w{1}\d{1,2}:\d{1,2}:\d{1,2}\.\d{1,3}\w)\sProcessImageName:\s(?<ProcessImageName>[+\w\s\._-]+),\sPid:\s(?<Pid>\d+),\sTotalTime:\s(?<TotalTime>\d+),\sCount:\s(?<CountValue>\d+),\sMaxTime:\s(?<MaxTime>\d+),\sMaxTimeFile:\s(?<MaxTimeFile>[\\\w\d\._\s~(){}$-<>\[\]=]+),\sEstimatedImpact:\s(?<EstimatedImpact>\d+)%'

    Get-Content -Path $DefenderLogPath -Tail $LastRows | Where {$_ -match "ProcessImageName"} | foreach {
        $currHash = [Ordered]@{}
        $currHash.'Timestamp' = ""
        $currHash.'ProcessImageName' = ""#Process image name
        $currHash.'Pid' = ""             #Process Id
        $currHash.'TotalTime' = ""       #The cumulative duration in milliseconds spent in scans of files accessed by this process
        $currHash.'CountValue' = ""      #The number of scanned files accessed by this process
        $currHash.'MaxTime' = ""         #The duration in milliseconds in the longest single scan of a file accessed by this process
        $currHash.'MaxTimeFile' = ""     #The path of the file accessed by this process for which the longest scan of MaxTime duration was recorded
        $currHash.'EstimatedImpact' = "" #The percentage of time spent in scans for files accessed by this process out of the period in which this process experienced scan activity
        $currHash.'OriginalLogLine' = ""

        if($_ -match $regex){
            $currHash.'Timestamp' = [datetime]$Matches.'Timestamp'
            $currHash.'ProcessImageName' = $Matches.'ProcessImageName'
            $currHash.'Pid' = $Matches.'Pid'
            $currHash.'TotalTime' = $Matches.'TotalTime'
            $currHash.'CountValue' = $Matches.'CountValue'
            $currHash.'MaxTime' = $Matches.'MaxTime'
            $currHash.'MaxTimeFile' = $($Matches.'MaxTimeFile' -replace "^\\Device\\HarddiskVolume\d","")
            $currHash.'EstimatedImpact' = [int]$Matches.'EstimatedImpact'
            $currHash.'OriginalLogLine' = $Matches.0
        
            #$Matches
        }
        else{
            $currObj.'OriginalLogLine' = $_
        }

        New-Object PSObject -Property $currHash
    }
}

<#
Examples
Get-ParsedDefenderProcesses | ft
Get-ParsedDefenderProcesses | Group-Object ProcessImageName | Sort Count -Descending | Select -First 15
Get-ParsedDefenderProcesses | Where {$_.EstimatedImpact -gt "50" -and $_.MaxTimeFile -notmatch "\\Windows\\System32\\"} | Sort EstimatedImpact -Descending | ft ProcessImageName,EstimatedImpact,TotalTime,CountValue,MaxTimeFile
#>
