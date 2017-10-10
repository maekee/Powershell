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
