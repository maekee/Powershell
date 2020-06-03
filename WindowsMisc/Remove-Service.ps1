#Sure.. there is a New-Service and Set-Service. But where is the Remove-Service?
#Here it is, feel free to improve

Function Remove-Service {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true, Position=0)][string]$ServiceName)

    if(Get-Service -Name $ServiceName -ErrorAction SilentlyContinue){
        $serviceObj = Get-WmiObject -Class Win32_Service -Filter "name='$ServiceName'"
        
        if($serviceObj){
            if($serviceObj.State -ne "Stopped"){
                [void]$serviceObj.StopService()
                #region Wait for Service to stop.. number of tries (i) x 5 seconds
                    For ($i=0; $i -le 10; $i++) {
                        if((Get-Service $ServiceName).Status -eq "Stopped"){
                            Write-Verbose "Successfully stopped service $ServiceName"
                            $RemoveService = $true
                        }
                        else{
                            $i++
                            Start-Sleep -Seconds 5
                            Write-Verbose "Waiting for service $ServiceName to stop..."
                        }
                    }
                #endregion
            }
            else{ $RemoveService = $true }
            
            if($RemoveService){ $serviceObj.delete() }
            
            else{ Write-Warning "Service did not stop within the expected time frame, no service will be removed" }
        }
    }
    else{
        Write-Warning "Service $ServiceName not found on $env:COMPUTERNAME"
    }
}
