 Function Get-ESClusterNodes{
    [CmdletBinding()]
    param(
        $ElasticSearchUri = 'http://localhost:9200',
        $NodeName
    )

    $JsonData = Invoke-WebRequest -Uri "$ElasticSearchUri/_nodes/_all" -Method Get -ContentType application/json -UseBasicParsing
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
