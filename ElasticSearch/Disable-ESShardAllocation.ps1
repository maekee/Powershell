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
    $ShardSettingOutput = Invoke-RestMethod -Method Put -Uri $FullUri -ContentType 'application/json' -Body $jsonbody -ErrorAction Stop -UseBasicParsing
        
    if($ShardSettingOutput.acknowledged){ Write-Verbose "Successfully disabled shard allocation $LogText" }
    else{ Write-Warning "Did not recieve a acknowledgement from elasticsearch, verify state" }
}
