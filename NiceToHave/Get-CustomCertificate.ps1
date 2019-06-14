#Me and my colleague talked about downloading certificates/view basic certificate information from
#internal web sites. So i had to throw this together.

Function Get-CustomCertificate{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][string]$Url = "https://nessus",
        [Parameter(Mandatory=$false)][string]$ExportCertificatePath,
        [switch]$ResolveIP,
        [switch]$UseProxy
    )

    begin{
        #region Parse to detect IP address
            if($Url -match '(?<ipaddr>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'){
                $UrlIP = $Matches.ipaddr
                Write-Verbose "Detected IP address $UrlIP in $Url"
            }
        #endregion

        #region Parse IP if ResolveIP parameter is specified
            if( $PSBoundParameters.ContainsKey('ResolveIP') -and $Url ){
                try{
                    $UrlHostName = [System.Net.Dns]::GetHostByAddress($UrlIP).HostName
                    Write-Verbose "Replaced `"$Url`" with `"$($Url -replace $UrlIP,$UrlHostName)`""
                    $Url = $Url -replace $UrlIP,$UrlHostName
                }
                catch{
                    Write-Verbose "Could not resolve IP $UrlIP, using `"$Url`""
                }
            }
        #endregion

        #region Making sure that https prefix exist
            if($Url -notmatch "^https"){
                if($Url -match "^http:"){
                    $Url = $Url -replace "http:","https:"
                    Write-Verbose "Replaced http with https and requesting `"$Url`""
                }
                else{
                    Write-Verbose "Added https prefix to `"$Url`" and requesting `"https://$($Url)`""
                    $Url = "https://$Url"
                }
            }
            else{
                Write-Verbose "Requesting `"$Url`"" 
            }
        #endregion
    }
    process{
        #region Add proxy configuration (No basic authentication = user/pass)
            if( $PSBoundParameters.ContainsKey('UseProxy') ){
                try{
                    $ProxyAddress = [System.Net.WebProxy]::GetDefaultProxy().Address
                    [System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy($ProxyAddress)
                    [System.Net.WebRequest]::DefaultWebProxy.credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
                    [System.Net.WebRequest]::DefaultWebProxy.BypassProxyOnLocal = $true
                }
                catch{
                    Write-Warning "Failed to configure DefaultWebProxy. Exception: $($_.Exception.Message)"
                }
            }
        #endregion

        #region Requesting website and trying to get certificate
            try{
                $webRequest = [Net.WebRequest]::Create($Url)
                $webResponse = $webRequest.GetResponse()
                if($webRequest.HaveResponse){ $cert = $webRequest.ServicePoint.Certificate }
            }
            catch {
                Write-Warning -Message "Error occured when getting certificate from `"$Url`". Exception: $($_.Exception.Message)"
            }
        #endregion

        #region Show Certificate
            if($cert){
                $cert
            }
        #endregion

        #region Export Certificate if parameter is specified
            if( $PSBoundParameters.ContainsKey('ExportCertificatePath') -and $cert ){
                try{
                    $exportCertName = $Url -replace "(\bhttp\b|\bhttps\b|\b$($env:USERDNSDOMAIN.ToLower())\b)"
                    $exportCertName = $exportCertName -replace "[^a-z0-9]",''
                    $CertificatePath = Join-Path $ExportCertificatePath "$($exportCertName).cer"

                    $bytes = $cert.Export([Security.Cryptography.X509Certificates.X509ContentType]::Cert)
                    Set-Content -value $bytes -Encoding Byte -path $CertificatePath -Force

                    if(Test-Path $CertificatePath){ Write-Verbose "Successfully exported certificate to `"$CertificatePath`"" }
                    else{ Write-Warning "Failed to export certificate to `"$CertificatePath`"" }
                }
                catch{
                    Write-Warning "Failed to export certificate to $ExportCertificatePath. Exception $($_.Exception.Message)"
                }
            }
        #endregion
    }
    end{
        #region Reset Proxy
            [System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy
        #endregion
    }
}
