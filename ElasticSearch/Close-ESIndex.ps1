 Function Close-ESIndex {
    [CmdletBinding()]
    param (
        $ElasticSearchUri = 'http://localhost:9200',
        [Parameter(Mandatory=$true)]$IndexName,
        [switch]$Force
    )

    $CurrentIndex = Get-ElasticSearchIndex -IndexName $IndexName
    if($CurrentIndex){
        if($CurrentIndex.status -ne "close" -or $Force){
            Write-Verbose "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Closing index $IndexName..."
            $closeOutput = Invoke-WebRequest -Method Post -Uri "$ElasticSearchUri/$IndexName/_close" -ContentType application/json
            Write-Verbose "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Close request complete with status: $($closeOutput.content)"
        }
        else{ Write-Warning "$IndexName is already in status close, use the force parameter if you still want to request the close index operation" }

    }
    else{ Write-Warning "Elasticsearch index $IndexName not found" }
}
