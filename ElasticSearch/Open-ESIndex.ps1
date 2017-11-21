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
            $closeOutput = Invoke-WebRequest -Method Post -Uri "$ElasticSearchUri/$IndexName/_open" -ContentType application/json -UseBasicParsing
            Write-Verbose "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Open request complete with status: $($closeOutput.content)"
        }
        else{ Write-Warning "$IndexName is already in status open, use the force parameter if you still want to request the open index operation" }

    }
    else{ Write-Warning "Elasticsearch index $IndexName not found" }
}
