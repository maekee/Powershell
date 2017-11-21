 Function Remove-ESSnapshot {
    [CmdletBinding()]
    param (
        $ElasticSearchUri = 'http://localhost:9200',
        [Parameter(Mandatory=$true)]$SnapshotRepository,
        [Parameter(Mandatory=$true)]$SnapshotName
    )

    $SnapshotRepos = @(Get-ESSnapshotRepository)
    if($SnapshotRepos.Count -ne 0 -and $SnapshotRepos.Name -contains $SnapshotRepository){
        
        $RepoSnapshots = @(Get-ESSnapshots -SnapshotRepository $SnapshotRepository)
        if($RepoSnapshots.snapshot -contains $SnapshotName){
           try{
                Write-Verbose "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Removing snapshot $SnapshotName from repository $SnapshotRepository..."
                Write-Verbose "Removing all files that are associated with snapshot $SnapshotName and not used by any other snapshots."
                
                try{ $RemovalResults = Invoke-WebRequest -Uri "$ElasticSearchUri/_snapshot/$SnapshotRepository/${SnapshotName}" -Method Delete -UseBasicParsing -ErrorAction Stop }
                catch{ Write-Warning $_.Exception.Message }
                
                Write-Verbose "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Snapshot removal status response: $($RemovalResults.Content)"
           }
           catch{ Write-Host $_.Exception.Message }
        }
        else{ Write-Warning "Snapshot $SnapshotName could not be found in repository $SnapshotRepository" }
    }
    else{ Write-Warning "Snapshot repository $SnapshotRepository not found, specify correct snapshot repository" }
}
