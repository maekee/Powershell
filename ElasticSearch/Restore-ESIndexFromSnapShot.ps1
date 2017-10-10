 Function Restore-ESIndexFromSnapShot {
    [CmdletBinding()]
    param (
        $ElasticSearchUri = 'http://localhost:9200',
        [Parameter(Mandatory=$true)]$SnapshotRepository,
        [Parameter(Mandatory=$true)]$SnapshotName,
        [Parameter(Mandatory=$false)][string[]]$IndicesToRestore,
        [switch]$ForceIndexCloseIfNeeded,
        [switch]$DoNotWaitForCompletion
    )
    
    if((Get-ElasticSearchSnapshotRepository).Name -contains $SnapshotRepository){
        $RepoSnapshots = @(Get-ElasticSearchSnapshots -SnapshotRepository $SnapshotRepository)
        if($RepoSnapshots.snapshot -contains $SnapshotName){

            $FullUri = "${ElasticSearchUri}/_snapshot/${SnapshotRepository}/${SnapshotName}/_restore"
            if(!($DoNotWaitForCompletion)){$FullUri = "${FullUri}?wait_for_completion=true"}
            else{ $FullUri = "${FullUri}?wait_for_completion=false"}

            if($IndicesToRestore){
                $hashbody = @{
                    "indices" = $($IndicesToRestore -join ',')
                    "ignore_unavailable" = 'true'
                    "include_global_state" = 'true'
                }
            }
            else{
                $hashbody = @{"ignore_unavailable" = 'true';"include_global_state" = 'true'}
            }
            $jsonbody = $hashbody | ConvertTo-Json

            #Closing Indices before restoring if parameter ForceIndexCloseIfNeeded is used
            if($ForceIndexCloseIfNeeded){
                #IndicesToRestore parameter is used = close selected indices
                if($IndicesToRestore){
                    Write-Verbose "Closing indices specified: $($IndicesToRestore -join ", ")"
                    $IndicesToRestore | Foreach {
                        if(Get-ElasticSearchIndex -ElasticSearchUri $ElasticSearchUri -IndexName $_){
                            Close-ElasticSearchIndex -ElasticSearchUri $ElasticSearchUri -IndexName $_ -Force
                        }
                        else{ Write-Verbose "Index $_ is missing, no close operation needed" }
                    }
                }
                else{
                    #IndicesToRestore parameter is NOT used = close all indices in snapshot
                    $SnapShotIndices = (Get-ElasticSearchSnapshots -ElasticSearchUri $ElasticSearchUri -SnapshotRepository $SnapshotRepository | Where {$_.snapshot -eq $SnapshotName}).indices
                    Write-Verbose "Closing all incices in snapshot $($SnapshotName): $($SnapShotIndices -join ", ")"
                    $SnapShotIndices | Foreach {
                        if(Get-ElasticSearchIndex -ElasticSearchUri $ElasticSearchUri -IndexName $_){
                            Close-ElasticSearchIndex -ElasticSearchUri $ElasticSearchUri -IndexName $_ -Force
                        }
                        else{ Write-Verbose "Index $_ is missing, no close operation needed" }
                    }
                }
            }

            try{
                if($IndicesToRestore){ Write-Verbose "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Restoring selected indices $($IndicesToRestore -join ',') from snapshot $SnapshotName to repository $SnapshotRepository..." }
                else{ Write-Verbose "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Restoring all indices from snapshot $SnapshotName to repository $SnapshotRepository..." }
                
                $SnapShotState = Invoke-RestMethod -Method Post -Uri $FullUri -ContentType 'application/json' -Body $jsonbody -ErrorAction Stop
                
                Write-Verbose "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Restored Shards: Total: $($SnapShotState.snapshot.shards.total), failed: $($SnapShotState.snapshot.shards.failed), successful: $($SnapShotState.snapshot.shards.successful)"
            }
            catch{ Write-Warning "Exception: $((ConvertFrom-Json -InputObject $_.ErrorDetails.Message).error.root_cause.reason)" }
        }
        else{ Write-Warning "Snapshot $SnapshotName not found in repository $SnapshotRepository" }
    }
    else{ Write-Warning "ElasticSearch snapshot repository $SnapshotRepository not found" }
}
