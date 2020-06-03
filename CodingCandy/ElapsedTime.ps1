#Nice trick to logg time information in scripts
$ElapsedTime = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "Script started - Elapsed Time: $($ElapsedTime.Elapsed.ToString())"
#Variables
Write-Host "Variables done - Elapsed Time: $($ElapsedTime.Elapsed.ToString())"
#Stuff happening
Write-Host "Part 1 - Declared stuff - Elapsed Time: $($ElapsedTime.Elapsed.ToString())"
#etc
Write-Host "Script finished - Elapsed Time: $($ElapsedTime.Elapsed.ToString())"
