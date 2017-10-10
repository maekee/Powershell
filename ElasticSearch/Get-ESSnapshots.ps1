 Function Get-ESSnapshots{
    [CmdletBinding()]
    param(
        $ElasticSearchUri = 'http://localhost:9200',
        [Parameter(Mandatory=$true)]$SnapshotRepository
    )

    if((Get-ESSnapshotRepository).Name -contains $SnapshotRepository){
        (ConvertFrom-Json -InputObject ( Invoke-WebRequest -Uri "$ElasticSearchUri/_snapshot/$SnapshotRepository/_all" -Method Get ).Content).snapshots
    }
    else{ Write-Warning "ElasticSearch snapshot repository $SnapshotRepository not found" }
}
