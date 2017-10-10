 Function Remove-ESIndex {
    [CmdletBinding()]
    param (
        $ElasticSearchUri = 'http://localhost:9200',
        [Parameter(Mandatory=$true)]$IndexName
    )

    try{
        $CurrentIndex = Get-ESIndex -IndexName $IndexName
        if($CurrentIndex){
            Write-Verbose "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Removing index $IndexName..."
            $removalOutput = Invoke-WebRequest -Method Delete -Uri "$($ElasticSearchUri)/${IndexName}" -ContentType application/json -ErrorAction Stop
            Write-Verbose "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Removal request complete with status: $($removalOutput.content)"
        }
        else{ Write-Warning "Elasticsearch index $IndexName not found" }
    }
    catch { Write-Warning "Exception: $((ConvertFrom-Json -InputObject $_.ErrorDetails.Message).error.reason)" }
}
