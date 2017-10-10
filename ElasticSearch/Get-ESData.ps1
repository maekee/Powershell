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
