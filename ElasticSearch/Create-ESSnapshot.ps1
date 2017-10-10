 Function Create-ESSnapshot {
    [CmdletBinding()]
    param (
        $ElasticSearchUri = 'http://localhost:9200',
        [Parameter(Mandatory=$true)]$SnapshotRepository,
        [Parameter(Mandatory=$false)][string[]]$IndicesToSnapShot,
        [Parameter(Mandatory=$true)]$SnapshotName,
        [switch]$DoNotWaitForCompletion
    )

    $SnapshotRepos = @(Get-ElasticSearchSnapshotRepository)
    
    if($SnapshotRepos.Count -ne 0){
        if($SnapshotRepos.Name -contains $SnapshotRepository){
            $FullUri = "${ElasticSearchUri}/_snapshot/${SnapshotRepository}/${SnapshotName}"
            if(!($DoNotWaitForCompletion)){$FullUri = "${FullUri}?wait_for_completion=true"}
            else{ $FullUri = "${FullUri}?wait_for_completion=false"}

            $RepoSnapshots = @(Get-ElasticSearchSnapshots -SnapshotRepository $SnapshotRepository)
            if($RepoSnapshots.snapshot -notcontains $SnapshotName){

                if($IndicesToSnapShot){
                    $hashbody = @{
                        "indices" = $($IndicesToSnapShot -join ',')
                        "ignore_unavailable" = 'true'
                        "include_global_state" = 'false'
                    }
                }
                else{ $hashbody = @{} }
                $jsonbody = $hashbody | ConvertTo-Json
                try{
                    Write-Verbose "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Creating snapshot $SnapshotName in repository $SnapshotRepository..."
                    
                    try{$SnapShotState = Invoke-RestMethod -Method Put -Uri $FullUri -ContentType 'application/json' -Body $jsonbody -ErrorAction Stop}
                    catch{ Write-Warning $_.Exception.Message }
                    
                    if(!($DoNotWaitForCompletion)){
                        Write-Verbose "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Snapshot $($SnapShotState.snapshot.snapshot) completed in $(($SnapShotState.snapshot.duration_in_millis)/1000) seconds with status $($SnapShotState.snapshot.state)"
                    }
                    else{ Write-Verbose "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Snapshot request sent, validate snapshot status manually when completed" }
                }
                catch { Write-Warning $_.Exception.Message }
            }
            else{ Write-Warning "Snapshot $SnapshotName already exists in repository $SnapshotRepository" }
        }
        else{ Write-Warning "Elasticsearch snapshot repository $SnapshotRepository not found, you need to create it" }
    }
    else{ Write-Warning "No Elasticsearch snapshot repository found, you need to create it" }
}
