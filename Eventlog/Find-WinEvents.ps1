Function Find-WinEvents {
    [CmdletBinding()]
    param(
        [string[]]$EventLogs = "Security", #(Get-EventLog -List).Log,
        [datetime]$StartTime = [datetime]::Now.AddHours(-1),
        [datetime]$EndTime = [datetime]::Now,
        [int[]]$EventIDs,
        [string]$RegExSearchString,
        [int]$MaxEventsPerLog
    )

    $ElapsedTime = [System.Diagnostics.Stopwatch]::StartNew()

    Write-Verbose -Message "EventLogs: $($EventLogs -join ", ")" -Verbose
    Write-Verbose -Message "Start Time: $($StartTime.ToString("yyyy-MM-dd HH:mm:ss"))" -Verbose
    Write-Verbose -Message "End Time: $($EndTime.ToString("yyyy-MM-dd HH:mm:ss"))" -Verbose

    $GetWinEventFilterHashTable = @{"StartTime" = $StartTime;EndTime = $EndTime}
    if($EventIDs){
        Write-Verbose -Message "Event IDs: $($EventIDs -join ", ")" -Verbose
        [void]$GetWinEventFilterHashTable.Add("ID",$EventID -join ",")
    }

    if($RegExSearchString){ Write-Verbose -Message "Search String: `"$RegExSearchString`"" -Verbose }
    if($MaxEventsPerLog){ Write-Verbose -Message "Max Events per EventLog: $MaxEventsPerLog" -Verbose }

    foreach($currLog in $EventLogs){
        Write-Verbose -Message "Searching $($currLog) log..." -Verbose

        $GetWinEventArgs = @{}
        if($MaxEventsPerLog){ [void]$GetWinEventArgs.Add("MaxEvents",$MaxEventsPerLog) }

        if($GetWinEventFilterHashTable.LogName){ $GetWinEventFilterHashTable.LogName = $currLog }
        else{ [void]$GetWinEventFilterHashTable.Add("LogName",$currLog) }

        [void]$GetWinEventArgs.Add("FilterHashtable",$GetWinEventFilterHashTable)
        Get-WinEvent @GetWinEventArgs -ErrorAction SilentlyContinue -Verbose:$false | Where { $_.ToXml() -match $RegExSearchString }
    }

    Write-Verbose -Message "Search completed in $($ElapsedTime.Elapsed.ToString())" -Verbose
}
