$CSEExtensionId = "E47248BA-94CC-49C4-BBB5-9EB7F05183D0"
$gporesults = @(dsquery * -filter "(&(gPCUserExtensionNames=*{$CSEExtensionId}*))")

if($gporesults.Count -gt 0){
    foreach ($gpoItem in $gporesults){
        Get-GPO -Guid ($gpoItem.Replace('"CN={','')).Split('}')[0] | Select DisplayName,Id,WmiFilter
    }
}
else{
    Write-Host "No GPO's found" -fore green
}
