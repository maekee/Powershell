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

    $response = Invoke-WebRequest -Uri $FullUri -Method Get -ContentType 'application/json' -UseBasicParsing
    ConvertFrom-Json -InputObject $response.Content
}
