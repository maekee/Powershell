 Function Get-ESSnapshotRepository {
    [CmdletBinding()]
    param($ElasticSearchUri = 'http://localhost:9200')
    
    $SnapShots = @((ConvertFrom-Json -InputObject (Invoke-WebRequest -Uri "${ElasticSearchUri}/_snapshot/" -Method Get -ContentType application/json -UseBasicParsing).Content))
    
    if($SnapShots.Count -ne 0){
        $SnapShotList = @($SnapShots | Get-Member | Where {$_.Membertype -eq "NoteProperty"}).Name
        $SnapShotList | foreach {     
            $CurrentObj = (ConvertFrom-Json -InputObject (Invoke-WebRequest -Uri "${ElasticSearchUri}/_snapshot/" -Method Get)).$_
            [PSCustomObject]@{ Name = $_;Type = $CurrentObj.type;Settings = $CurrentObj.settings}
        }
    }
    else{ $null }
}
