 Function Get-ESRunningSnapshots{
    [CmdletBinding()]
    param (
        $ElasticSearchUri = 'http://localhost:9200',
        [Parameter(Mandatory=$true)]$SnapshotRepository
    )
    
    $FullUri = "$ElasticSearchUri/_snapshot/$SnapshotRepository/_current"
    
    if((Get-ElasticSearchSnapshotRepository).Name -contains $SnapshotRepository){
        try{
            $runningSnapsList = Invoke-RestMethod -Method Get -Uri $FullUri -ContentType 'application/json' -ErrorAction Stop
            if($runningSnapsList.snapshots.count -gt 0){
                $runningSnapsList.snapshots
            }
            else{ Write-Verbose "No currently running snapshot in repository $SnapshotRepository" }
        }
        catch { Write-Warning "Exception: $((ConvertFrom-Json -InputObject $_.ErrorDetails.Message).error.reason)" }
    }
    else{ Write-Warning "ElasticSearch snapshot repository $SnapshotRepository not found" }
}
