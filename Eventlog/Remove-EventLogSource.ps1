 Function Remove-EventLogSource{
    param($SourceName)

    try{ [System.Diagnostics.EventLog]::DeleteEventSource($SourceName) }
    catch{ Write-Error "Error occurred while deleting eventlog source $SourceName" }
}
