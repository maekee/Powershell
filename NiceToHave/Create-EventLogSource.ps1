 Function Create-EventLogSource{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]$LogName,
        [Parameter(Mandatory=$true, Position=1)]$SourceName
    )

    try{
        if([System.Diagnostics.EventLog]::GetEventLogs().Log -notcontains $LogName){
            Write-Warning "LogName `"$LogName`" does not exist"
        }
        else{
            if([System.Diagnostics.EventLog]::SourceExists($SourceName)){ Write-Verbose "Source `"$SourceName`" already exists" }
            else{
                [System.Diagnostics.EventLog]::CreateEventSource($SourceName, $LogName)
                Write-Verbose "Successfully created source $SourceName"
            }
        }
    }
    catch{
        if($_.FullyQualifiedErrorId -eq "SecurityException"){
            Write-Error "The source was not found, but some or all event logs could not be searched, elevate PowerShell and try run again"
        }
        else{ Write-Error "Error when creating source $SourceName. Exception: $($_.Exception.Message)" }
    }
}
