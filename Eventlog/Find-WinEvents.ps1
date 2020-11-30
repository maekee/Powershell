Function Find-WinEvents {
    <# 
    .SYNOPSIS
        Gets Windows events and also supports searching the underlying XML
    .DESCRIPTION
        The function uses Get-WinEvent but adds an easy way of searching all common event logs and supports regex searching.
    .PARAMETER EventLogs
        Optional parameter for which eventlogs should be searched, default all common (result from Get-EventLog -List)
    .PARAMETER StartTime
        Optional from which time to start search, default one hour ago
    .PARAMETER EndTime 
        Optional for the latest event. default now
    .PARAMETER RegExSearchString
        Optional string that will be searched for in the underlying XML (all fields). Supports regex because of the underlying use of match.
    .PARAMETER EventLevels 
        Optional parameter to specify Levels (severity), default all
    .PARAMETER EventIDs 
        Optional parameter to specify Event IDs, default all
    .PARAMETER MaxEventsPerLog 
        Optional how many events that should be limited per eventlog, to set limit to all event just use Select-Object -Last x yourself
    .EXAMPLE
        Find-WinEvents -EventLogs Application -EventLevels Information -MaxEventsPerLog 1
        Finds the latest information event in the Application event log
    .EXAMPLE
        Find-WinEvents -EventLogs Security -RegExSearchString "qwinsta"
        Finds all events containing the word qwinsta the last hour in the security event log
    .EXAMPLE
        Find-WinEvents -EventLogs System -EventLevels error,warning -MaxEventsPerLog 10
        Finds error and warning events in the System eventlog and limits to the last 10
    .NOTES
        AUTHOR: Micke Sundqvist
        LASTEDIT: 2020-11-30
        VERSION: 1.0
        PREREQUISITE: Admin permission to read from the Security event log
        CHANGELOG: 1.0.0 - Initial Release
    #>
    [CmdletBinding()]
    param(
        [string[]]$EventLogs = (Get-EventLog -List).Log,
        [datetime]$StartTime = [datetime]::Now.AddHours(-1),
        [datetime]$EndTime = [datetime]::Now,
        [string]$RegExSearchString,
        [string[]]$EventLevels,
        [int[]]$EventIDs,
        [int]$MaxEventsPerLog
    )

    $ElapsedTime = [System.Diagnostics.Stopwatch]::StartNew()

    Write-Verbose -Message "EventLogs: $($EventLogs -join ", ")"
    Write-Verbose -Message "Start Time: $($StartTime.ToString("yyyy-MM-dd HH:mm:ss"))"
    Write-Verbose -Message "End Time: $($EndTime.ToString("yyyy-MM-dd HH:mm:ss"))"

    $GetWinEventFilterHashTable = @{"StartTime" = $StartTime;EndTime = $EndTime}

    #region Optional parameter EventLevels
        if($EventLevels){
            #region Reverse value->Key function
                Function Get-EventLevelName{
                    param($LevelHash,$LevelID)
                    ($LevelHash.GetEnumerator() | Where {$_.Value -eq $LevelID})[0].Name
                }
            #endregion
        
            #region Build EventLevel hash from enum
                $StdEventLevelHash = @{}
                [System.Diagnostics.Eventing.Reader.StandardEventLevel] | Get-Member -Static -MemberType Property | Foreach {
                    $StdEventLevelHash.Add($_.Name, [System.Diagnostics.Eventing.Reader.StandardEventLevel]::$($_.Name).value__ )
                }
                $StdEventLevelHash.Add("Info",4)
                $StdEventLevelHash.Add("Information",4)
            #endregion

            #region Generate parameter array
                $EventLevelArg = @()
                foreach($EventLevel in $EventLevels){
                    if($EventLevel -in $StdEventLevelHash.Keys){
                        $EventLevelArg += $StdEventLevelHash[$EventLevel]
                    }
                    else{
                        Write-Warning -Message "Event level `"$EventLevel`" is not a valid level defined in [System.Diagnostics.Eventing.Reader.StandardEventLevel], skipping..."
                    }
                }
            #endregion

            #region Log and add to Get-WinEvent filterhashtable
                if($EventLevelArg.Count -gt 0){
                    Write-Verbose -Message "Event Levels: $(($EventLevelArg | Foreach {Get-EventLevelName -LevelHash $StdEventLevelHash -LevelID $_}) -join ", ")"
                    [void]$GetWinEventFilterHashTable.Add("Level",$EventLevelArg)
                }
            #endregion
        }
    #endregion

    #region Optional parameter EventIDs
        if($EventIDs){
            Write-Verbose -Message "Event IDs: $($EventIDs -join ", ")"
            [void]$GetWinEventFilterHashTable.Add("ID",$EventID -join ",")
        }
    #endregion

    #region Optional parameter RegExSearchString and MaxEventsPerLog
        if($RegExSearchString){ Write-Verbose -Message "Search String: `"$RegExSearchString`"" }
        if($MaxEventsPerLog){ Write-Verbose -Message "Max Events per EventLog: $MaxEventsPerLog" }
    #endregion

    foreach($currLog in $EventLogs){
        Write-Verbose -Message "Searching $($currLog) log..."

        $GetWinEventArgs = @{}
        if($MaxEventsPerLog){ [void]$GetWinEventArgs.Add("MaxEvents",$MaxEventsPerLog) }

        if($GetWinEventFilterHashTable.LogName){ $GetWinEventFilterHashTable.LogName = $currLog }
        else{ [void]$GetWinEventFilterHashTable.Add("LogName",$currLog) }

        [void]$GetWinEventArgs.Add("FilterHashtable",$GetWinEventFilterHashTable)
        
        try{
            Get-WinEvent @GetWinEventArgs -Verbose:$false -ErrorAction Stop | Where { $_.ToXml() -match $RegExSearchString }
        }
        catch{
            if($_.FullyQualifiedErrorId -match "NoMatchingEventsFound"){ continue }
            elseif($_.Exception.Message -match "unauthorized operation" -or $_.Exception.InnerException.HResult -match "2147024891"){ Write-Warning -Message "Validate that you run elevated and have permissions to view the `"$($currLog.ToLower())`" eventlog. Exception: $($_.Exception.Message)" }
            else{ Write-Warning -Message "Error occcured. Exception: $($_.Exception.Message)" }
        }
    }

    Write-Verbose -Message "Search completed in $($ElapsedTime.Elapsed.ToString())"
}
