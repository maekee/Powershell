 Function Get-ESClusterNodes{
    [CmdletBinding()]
    param(
        $ElasticSearchUri = 'http://localhost:9200',
        $NodeName
    )

    $JsonData = Invoke-WebRequest -Uri "$ElasticSearchUri/_nodes/_all" -Method Get -ContentType application/json
    $JsonObj = ConvertFrom-Json -InputObject $JsonData.Content
    
    if( @($JsonObj.nodes).count -ne 0 ){
        $NodeIdList =  @($JsonObj.nodes | Get-Member | Where {$_.Membertype -eq "NoteProperty"}).Name
        $ObjList = @()
        $ObjList = $NodeIdList | foreach { $JsonObj.nodes.$($_) }
    }
    else{ Write-Verbose "No elasticsearch nodes found" }

    if($NodeName){ $ObjList | Where {$_.Name -eq $NodeName} }
    else{$ObjList}
}

Function Get-ESVersion {
    [CmdletBinding()]
    param ( $ElasticSearchUri = 'http://localhost:9200' )

    $ClusterData = ConvertFrom-Json -InputObject (Invoke-WebRequest -Uri $ElasticSearchUri -Method Get -ContentType "application/json").Content
    $NodesObj = ConvertFrom-Json -InputObject (Invoke-WebRequest -Uri "$ElasticSearchUri/_nodes/_all/name,version" -Method Get -ContentType "application/json").Content
    $NodesIdList = @($NodesObj.nodes | Get-Member | Where {$_.Membertype -eq "NoteProperty"}).Name

    $HashNodes = @{}
    Foreach($ESNodeId in $NodesIdList){ $HashNodes.Add($($NodesObj.nodes.$ESNodeId.name),$($NodesObj.nodes.$ESNodeId.version)) }

    if(($HashNodes.Values | Select -Unique).Count -eq 1){
        if($($HashNodes.Values | Select -Unique) -eq $ClusterData.version.number){ $versionMatchValue = $true }
        else{ $versionMatchValue = $false }
    }
    else{ $versionMatchValue = $false }

    [PSCustomObject]@{
        Cluster_name = $ClusterData.cluster_name
        Cluster_version = $ClusterData.version.number
        Cluster_build_hash = $ClusterData.version.build_hash
        Cluster_lucene_version = $ClusterData.version.lucene_version
        Cluster_nodes = $HashNodes
        Versions_match = $versionMatchValue
    }
}
Function Get-ESShards {
    [CmdletBinding()]
    param (
        $ElasticSearchUri = 'http://localhost:9200',
        $Filter,
        [ValidateSet('AllShards','OnlyPrimaryShards','OnlyReplicaShards')]$ShardTypes = 'AllShards',
        [switch]$IncludeKibanaIndex
    )

    $AllShards = ConvertFrom-Json -InputObject (Invoke-WebRequest -Uri "$ElasticSearchUri/_cat/shards?format=json" -Method Get -ContentType "application/json").Content

    #Filtering output
    if(!($IncludeKibanaIndex)){ $AllShards = $AllShards | Where {$_.index -ne ".kibana" }}
    if($filter){ $AllShards = $AllShards | Where {$_.index -match $Filter} }
    if($ShardTypes -eq 'OnlyPrimaryShards'){ $AllShards = $AllShards | Where {$_.prirep -eq 'p'} }
    elseif($ShardTypes -eq 'OnlyReplicaShards'){ $AllShards = $AllShards | Where {$_.prirep -eq 'r'} }

    $AllShards
}

Function Disable-ESShardAllocation {
    [CmdletBinding()]
    param (
        $ElasticSearchUri = 'http://localhost:9200',
        [ValidateSet('UntilESRestart','Persistent')]$Period = 'UntilESRestart'
    )
    
    if($Period -eq 'UntilESRestart'){
        $PeriodValue = "transient"
        $LogText = "until next elasticsearch restart"
    }
    else{
        $PeriodValue = "persistent"
        $LogText = "permanently"
    }
    
    $hashbody = @{$PeriodValue = @{"cluster.routing.allocation.enable" = "none"}}
    $jsonbody = $hashbody | ConvertTo-Json

    $FullUri = "$ElasticSearchUri/_cluster/settings"
    $ShardSettingOutput = Invoke-RestMethod -Method Put -Uri $FullUri -ContentType 'application/json' -Body $jsonbody -ErrorAction Stop
        
    if($ShardSettingOutput.acknowledged){ Write-Verbose "Successfully disabled shard allocation $LogText" }
    else{ Write-Warning "Did not recieve a acknowledgement from elasticsearch, verify state" }
}
Function Enable-ESShardAllocation {
    [CmdletBinding()]
    param (
        $ElasticSearchUri = 'http://localhost:9200',
        [ValidateSet('UntilESRestart','Persistent')]$Period = 'UntilESRestart'
    )

    if($Period -eq 'UntilESRestart'){
        $PeriodValue = "transient"
        $LogText = "until next elasticsearch restart"
    }
    else{
        $PeriodValue = "persistent"
        $LogText = "permanently"
    }

    $hashbody = @{$PeriodValue = @{"cluster.routing.allocation.enable" = "all"}}
    $jsonbody = $hashbody | ConvertTo-Json

    $FullUri = "$ElasticSearchUri/_cluster/settings"
    $ShardSettingOutput = Invoke-RestMethod -Method Put -Uri $FullUri -ContentType 'application/json' -Body $jsonbody -ErrorAction Stop
        
    if($ShardSettingOutput.acknowledged){ Write-Verbose "Successfully enabled shard allocation $LogText" }
    else{ Write-Warning "Did not recieve a acknowledgement from elasticsearch, verify state" }
}
Function Reset-ESShardAllocation{
    [CmdletBinding()]
    param (
        $ElasticSearchUri = 'http://localhost:9200',
        [ValidateSet('Transient','Persistent','Both')]$SettingType = 'Both'
    )

    if($SettingType -eq 'Transient'){ $jsonbody = '{"transient":  {"cluster.routing.allocation.enable":  null}}' }
    elseif($SettingType -eq 'Persistent'){ $jsonbody = '{"persistent":  {"cluster.routing.allocation.enable":  null}}' }
    else{ $jsonbody = '{"transient":  {"cluster.routing.allocation.enable":  null},"persistent":  {"cluster.routing.allocation.enable":  null}}' }

    $ShardSettingOutput = Invoke-RestMethod -Method Put -Uri "$ElasticSearchUri/_cluster/settings" -ContentType 'application/json' -Body $jsonbody -ErrorAction Stop

    if($ShardSettingOutput.acknowledged){ Write-Verbose "Successfully reset shard allocation settings" }
    else{ Write-Warning "Did not recieve a acknowledgement from elasticsearch, verify state" }
}

Function Get-ESStats{
    [CmdletBinding()]
    param (
        [string]$Uri = 'http://127.0.0.1:9200',
        [ValidateSet('stats','nodes','nodesstatsjvmhttp','clusterstats','clusterhealth','winlogbeatindexresultinfo','pendingTasks')]$StatisticsType = 'stats'
    )
    #https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-stats.html
    #https://www.datadoghq.com/blog/collect-elasticsearch-metrics/#node-stats-api

    if($StatisticsType -eq 'stats'){ [Uri]$FullUri = "$Uri/_stats" }
    if($StatisticsType -eq 'nodes'){ [Uri]$FullUri = "$Uri/_nodes/stats" }
    if($StatisticsType -eq 'nodesstatsjvmhttp'){ [Uri]$FullUri = "$Uri/_nodes/stats/jvm,http" }
    if($StatisticsType -eq 'clusterstats'){ [Uri]$FullUri = "$Uri/_cluster/stats" }
    if($StatisticsType -eq 'clusterhealth'){ [Uri]$FullUri = "$Uri/_cluster/health" }
    if($StatisticsType -eq 'winlogbeatindexresultinfo'){ [Uri]$FullUri = "$Uri/winlogbeat-*/_search" }
    if($StatisticsType -eq 'pendingTasks'){
        [Uri]$FullUri = "$Uri/_cluster/pending_tasks"
        Write-Verbose "If all is well, you’ll receive an empty list"
        #Otherwise, you’ll receive information about each pending task’s priority, how 
        #long it has been waiting in the queue, and what action it represents.
    }

    $response = Invoke-WebRequest -Uri $FullUri -Method Get -ContentType 'application/json'
    ConvertFrom-Json -InputObject $response.Content
}

Function Get-ESIndex {
    [CmdletBinding()]
    param (
        $ElasticSearchUri = 'http://localhost:9200',
        [string[]]$IndexName,
        $Filter,
        [switch]$IncludeKibanaIndex
    )

    $FullUri = "$ElasticSearchUri/_cat/indices?format=json"

    try{
        $APIoutput = Invoke-WebRequest -Method Get -Uri $FullUri -ContentType application/json -ErrorAction Stop
        $JsonObj = ConvertFrom-Json -InputObject $APIoutput -ErrorAction Stop
        $JsonObj = $JsonObj | Sort index
    }
    catch { Write-Warning $_.Exception.Message }

    if(!($IncludeKibanaIndex)){ $JsonObj = $JsonObj | Where {$_.index -ne ".kibana"} }
    if($IndexName){ $JsonObj = $JsonObj | Where {$IndexName -contains $_.index} }
    if($filter){ $JsonObj = $JsonObj | Where {$_.index -match $Filter} }
    
    $JsonObj
}
Function Close-ESIndex {
    [CmdletBinding()]
    param (
        $ElasticSearchUri = 'http://localhost:9200',
        [Parameter(Mandatory=$true)]$IndexName,
        [switch]$Force
    )

    $CurrentIndex = Get-ESIndex -IndexName $IndexName
    if($CurrentIndex){
        if($CurrentIndex.status -ne "close" -or $Force){
            Write-Verbose "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Closing index $IndexName..."
            $closeOutput = Invoke-WebRequest -Method Post -Uri "$ElasticSearchUri/$IndexName/_close" -ContentType application/json
            Write-Verbose "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Close request complete with status: $($closeOutput.content)"
        }
        else{ Write-Warning "$IndexName is already in status close, use the force parameter if you still want to request the close index operation" }

    }
    else{ Write-Warning "Elasticsearch index $IndexName not found" }
}
Function Open-ESIndex {
    [CmdletBinding()]
    param (
        $ElasticSearchUri = 'http://localhost:9200',
        [Parameter(Mandatory=$true)]$IndexName,
        [switch]$Force
    )

    $CurrentIndex = Get-ESIndex -IndexName $IndexName
    if($CurrentIndex){
        if($CurrentIndex.status -ne "open" -or $Force){
            Write-Verbose "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Opening index $IndexName..."
            $closeOutput = Invoke-WebRequest -Method Post -Uri "$ElasticSearchUri/$IndexName/_open" -ContentType application/json
            Write-Verbose "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Open request complete with status: $($closeOutput.content)"
        }
        else{ Write-Warning "$IndexName is already in status open, use the force parameter if you still want to request the open index operation" }

    }
    else{ Write-Warning "Elasticsearch index $IndexName not found" }
}
Function Remove-ESIndex {
    [CmdletBinding()]
    param (
        $ElasticSearchUri = 'http://localhost:9200',
        [Parameter(Mandatory=$true)]$IndexName
    )

    try{
        $CurrentIndex = Get-ESIndex -IndexName $IndexName
        if($CurrentIndex){
            Write-Verbose "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Removing index $IndexName..."
            $removalOutput = Invoke-WebRequest -Method Delete -Uri "$($ElasticSearchUri)/${IndexName}" -ContentType application/json -ErrorAction Stop
            Write-Verbose "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Removal request complete with status: $($removalOutput.content)"
        }
        else{ Write-Warning "Elasticsearch index $IndexName not found" }
    }
    catch { Write-Warning "Exception: $((ConvertFrom-Json -InputObject $_.ErrorDetails.Message).error.reason)" }
}

Function Get-ESIndexTemplates{
    [CmdletBinding()]
    param($ElasticSearchUri = 'http://localhost:9200')

    $TemplateData = Invoke-WebRequest -Uri "$ElasticSearchUri/_template" -Method Get -ContentType application/json
    $TemplateObj = @(ConvertFrom-Json -InputObject $TemplateData.Content)

    if($TemplateObj.Count -ne 0){
        $TemplateList = @($TemplateObj | Get-Member | Where {$_.Membertype -eq "NoteProperty"}).Name
        $TemplateList | foreach {     
            $CurrentObj = (ConvertFrom-Json -InputObject (Invoke-WebRequest -Uri "$ElasticSearchUri/_template" -Method Get -ContentType application/json).Content).$_
            [PSCustomObject]@{ Name = $_;Order = $CurrentObj.order;Template = $CurrentObj.template;Settings = $CurrentObj.settings;Mappings = $CurrentObj.mappings;Aliases = $CurrentObj.aliases}
        }
    }
    else{ Write-Verbose "No templates found" }
}

Function Get-ESSnapshotRepository {
    [CmdletBinding()]
    param($ElasticSearchUri = 'http://localhost:9200')
    
    $SnapShots = @((ConvertFrom-Json -InputObject (Invoke-WebRequest -Uri "${ElasticSearchUri}/_snapshot/" -Method Get -ContentType application/json).Content))
    
    if($SnapShots.Count -ne 0){
        $SnapShotList = @($SnapShots | Get-Member | Where {$_.Membertype -eq "NoteProperty"}).Name
        $SnapShotList | foreach {     
            $CurrentObj = (ConvertFrom-Json -InputObject (Invoke-WebRequest -Uri "${ElasticSearchUri}/_snapshot/" -Method Get)).$_
            [PSCustomObject]@{ Name = $_;Type = $CurrentObj.type;Settings = $CurrentObj.settings}
        }
    }
    else{ $null }
}
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
Function Create-ESSnapshot {
    [CmdletBinding()]
    param (
        $ElasticSearchUri = 'http://localhost:9200',
        [Parameter(Mandatory=$true)]$SnapshotRepository,
        [Parameter(Mandatory=$false)][string[]]$IndicesToSnapShot,
        [Parameter(Mandatory=$true)]$SnapshotName,
        [switch]$DoNotWaitForCompletion
    )

    $SnapshotRepos = @(Get-ESSnapshotRepository)
    
    if($SnapshotRepos.Count -ne 0){
        if($SnapshotRepos.Name -contains $SnapshotRepository){
            $FullUri = "${ElasticSearchUri}/_snapshot/${SnapshotRepository}/${SnapshotName}"
            if(!($DoNotWaitForCompletion)){$FullUri = "${FullUri}?wait_for_completion=true"}
            else{ $FullUri = "${FullUri}?wait_for_completion=false"}

            $RepoSnapshots = @(Get-ESSnapshots -SnapshotRepository $SnapshotRepository)
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
                
                try{ $RemovalResults = Invoke-WebRequest -Uri "$ElasticSearchUri/_snapshot/$SnapshotRepository/${SnapshotName}" -Method Delete -ErrorAction Stop }
                catch{ Write-Warning $_.Exception.Message }
                
                Write-Verbose "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Snapshot removal status response: $($RemovalResults.Content)"
           }
           catch{ Write-Host $_.Exception.Message }
        }
        else{ Write-Warning "Snapshot $SnapshotName could not be found in repository $SnapshotRepository" }
    }
    else{ Write-Warning "Snapshot repository $SnapshotRepository not found, specify correct snapshot repository" }
}
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
    
    if((Get-ESSnapshotRepository).Name -contains $SnapshotRepository){
        $RepoSnapshots = @(Get-ESSnapshots -SnapshotRepository $SnapshotRepository)
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
                        if(Get-ESIndex -ElasticSearchUri $ElasticSearchUri -IndexName $_){
                            Close-ESIndex -ElasticSearchUri $ElasticSearchUri -IndexName $_ -Force
                        }
                        else{ Write-Verbose "Index $_ is missing, no close operation needed" }
                    }
                }
                else{
                    #IndicesToRestore parameter is NOT used = close all indices in snapshot
                    $SnapShotIndices = (Get-ESSnapshots -ElasticSearchUri $ElasticSearchUri -SnapshotRepository $SnapshotRepository | Where {$_.snapshot -eq $SnapshotName}).indices
                    Write-Verbose "Closing all incices in snapshot $($SnapshotName): $($SnapShotIndices -join ", ")"
                    $SnapShotIndices | Foreach {
                        if(Get-ESIndex -ElasticSearchUri $ElasticSearchUri -IndexName $_){
                            Close-ESIndex -ElasticSearchUri $ElasticSearchUri -IndexName $_ -Force
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
Function Get-ESRunningSnapshots{
    [CmdletBinding()]
    param (
        $ElasticSearchUri = 'http://localhost:9200',
        [Parameter(Mandatory=$true)]$SnapshotRepository
    )
    
    $FullUri = "$ElasticSearchUri/_snapshot/$SnapshotRepository/_current"
    
    if((Get-ESSnapshotRepository).Name -contains $SnapshotRepository){
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
Function Get-ESData{
    param(
        $ElasticSearchUri = 'http://localhost:9200',
        $DSLQuery
    )

    $SearchResults = (ConvertFrom-Json -InputObject (Invoke-WebRequest -Uri "$ElasticSearchUri/_search" -Method Post -Body $DSLQuery -ContentType "application/json").Content)
    
    New-Object PSObject -Property @{
        'Total' = $SearchResults.hits.total
        'Max_Score' = $SearchResults.hits.max_score
        'Hits' = $SearchResults.hits.hits
    }
} 
