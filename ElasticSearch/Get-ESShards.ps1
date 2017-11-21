 Function Get-ESShards {
    [CmdletBinding()]
    param (
        $ElasticSearchUri = 'http://localhost:9200',
        $Filter,
        [ValidateSet('AllShards','OnlyPrimaryShards','OnlyReplicaShards')]$ShardTypes = 'AllShards',
        [switch]$IncludeKibanaIndex
    )

    $AllShards = ConvertFrom-Json -InputObject (Invoke-WebRequest -Uri "$ElasticSearchUri/_cat/shards?format=json" -Method Get -ContentType "application/json" -UseBasicParsing).Content

    #Filtering output
    if(!($IncludeKibanaIndex)){ $AllShards = $AllShards | Where {$_.index -ne ".kibana" }}
    if($filter){ $AllShards = $AllShards | Where {$_.index -match $Filter} }
    if($ShardTypes -eq 'OnlyPrimaryShards'){ $AllShards = $AllShards | Where {$_.prirep -eq 'p'} }
    elseif($ShardTypes -eq 'OnlyReplicaShards'){ $AllShards = $AllShards | Where {$_.prirep -eq 'r'} }

    $AllShards
}
