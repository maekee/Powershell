#This function searches in all eventlogs/channels

Function Get-AllEvents {
    [CmdletBinding()]
    param(
        $LastMinutes = 5,
        [string[]]$NotEventIDs
    )

    #region Event logs
        try{$TheLogs = Get-WinEvent -ListLog * -ErrorAction Stop }
        catch{ Write-Warning -Message "Some Eventlogs could not be collected, make sure you run this elevated if you need ALL logs"}

        $TheLogs = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue
    #endregion

    $JustNow = (Get-Date) - (New-TimeSpan -Minutes $LastMinutes)
    $Results = New-Object System.Collections.ArrayList

    $i = 1
    foreach($TheLog in $TheLogs){
        Write-Progress -Activity "Collecting events from $($TheLogs.Count ) eventlogs, generated the last $LastMinutes minutes" -Status "$i/$($TheLogs.Count)" -PercentComplete ($i / $TheLogs.Count*100)
        try{ Get-WinEvent -FilterHashtable @{LogName=$TheLog.LogName;StartTime=$JustNow } -ErrorAction Stop | Foreach {[void]$Results.Add($_)} }
        catch{
            if($_.Exception.Message -notmatch "No events were found"){
                Write-Warning $_.Exception.Message
            }
        }
        $i++
    }
    $Results | Where {$_.Id -notin $NotEventIDs}
} 
