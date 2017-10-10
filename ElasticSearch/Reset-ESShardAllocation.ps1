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
