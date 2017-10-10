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
