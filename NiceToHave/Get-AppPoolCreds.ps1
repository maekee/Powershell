#This is a nice way to get IIS Application Pool Credentials

$appPools = Get-WebConfiguration -Filter '/system.applicationHost/applicationPools/add'
foreach($appPool in $appPools){
  if($appPool.ProcessModel.identityType -eq "SpecificUser")
  {
    Write-Host $appPool.Name -ForegroundColor Green -NoNewline
    Write-Host " -"$appPool.ProcessModel.UserName"="$appPool.ProcessModel.Password
  }
}

#Original URL by Nik Charlebois: http://nikcharlebois.com/easily-retrieve-iis-applicationpool-credentials/
