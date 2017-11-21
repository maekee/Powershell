 Function Get-ESIndexTemplates{
    [CmdletBinding()]
    param($ElasticSearchUri = 'http://localhost:9200')

    $TemplateData = Invoke-WebRequest -Uri "$ElasticSearchUri/_template" -Method Get -ContentType application/json
    $TemplateObj = @(ConvertFrom-Json -InputObject $TemplateData.Content)

    if($TemplateObj.Count -ne 0){
        $TemplateList = @($TemplateObj | Get-Member | Where {$_.Membertype -eq "NoteProperty"}).Name
        $TemplateList | foreach {     
            $CurrentObj = (ConvertFrom-Json -InputObject (Invoke-WebRequest -Uri "$ElasticSearchUri/_template" -Method Get -ContentType application/json -UseBasicParsing).Content).$_
            [PSCustomObject]@{ Name = $_;Order = $CurrentObj.order;Template = $CurrentObj.template;Settings = $CurrentObj.settings;Mappings = $CurrentObj.mappings;Aliases = $CurrentObj.aliases}
        }
    }
    else{ Write-Verbose "No templates found" }
}
