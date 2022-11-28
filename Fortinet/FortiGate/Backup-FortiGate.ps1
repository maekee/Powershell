Function Backup-FortiGate{
<#
    .SYNOPSIS
    Executes FortiGate configuration backup to disk

    .DESCRIPTION
    Uses the FortiGate API to export the full configuration of a FortiGate device (over TLS 1.2).

    .PARAMETER APIToken
    Parameter to specify the FortiGate REST API token generated on the FortiGate.

    .PARAMETER Hostname
    Parameter to specify the hostname/FQDN of the FortiGate device (must match certificate CN/SAN-names used on device)

    .PARAMETER ExportFolder
    Parameter to specify which directory to export the configuration to

    .PARAMETER EncryptedBackupPassword
    Optional parameter to specify configuration encryption password.
    Important: VPN certificates are only included if backup is encrypted.

    .EXAMPLE
    Backup-FortiGate -APIToken $SecureStringToken -Hostname "fgt1.domain.com" -ExportFolder C:\Backup\FortiGate
    Backs up FortiGate to C:\BackupFortiGate and authenticates with API token in variable $SecureStringToken
    
    Backup-FortiGate -Hostname "fgt1.domain.com" -ExportFolder C:\Backup\FortiGate -Verbose
    Interactive question for APIToken, then backs up FortiGate to C:\Backup\FortiGate with verbose logging

    Backup-FortiGate -APIToken $SecureStringToken -Hostname "fgt1.domain.com" -ExportFolder C:\Backup\FortiGate -EncryptedBackupPassword $EncryptedBackupPassword
    Backs up FortiGate encrypted to C:\BackupFortiGate and authenticates with API token in variable $SecureStringToken

    .NOTES
    Script uses Tls1.2 for .NET FW

    Necessary API Profile access permissions needs to be in place for API call to do a complete backup.
    For full configuration backups, an administrator with full read-write access is required.
    
    CLI backup Information (probably the same for API calls)
    Read-only administrators can create backups via CLI with some restrictions.
    The following information will not be contained when a read-only administrator creates a backup:
    - Super_admin settings
    - Administrator profiles with more privileges than the read-only admin
    - If the admin is restricted to a VDOM, any settings in other VDOMs

    Read-only administrators can only see limited information
    Password hashes and some other settings will not be visible.

    Fortinet Technical Tip:
    https://community.fortinet.com/t5/FortiGate/Technical-Tip-Read-only-administrators-and-configuration-backup/ta-p/193961

    If you are worried about leaking fortigate admin API token and trusted hosts are unsafe, you can use Automation Stiches
    and backup to an sftp/tftp location. But then you have to specify sftp user/pass in cleartext in the stitch.

    Known issue: Diacritics will be displayed incorrectly (Encoding issue with Invoke-RestMethod in PS 5.1)
    Author:      @mickesunkan
    Github:      https://github.com/maekee/Powershell
    Version:     v1.0 (2022-11-28)
    #>
    param(
        [Parameter(Mandatory=$true)][System.Security.SecureString]$APIToken,
        [Parameter(Mandatory=$true)][string]$Hostname,
        [Parameter(Mandatory=$true)][string]$ExportFolder,
        [Parameter(Mandatory=$false)][System.Security.SecureString]$EncryptedBackupPassword
    )

    if(Test-Connection $Hostname -Count 1 -ErrorAction SilentlyContinue){
        if(Test-Path -Path $ExportFolder){

            Write-Verbose -Message "Supplied FortiGate hostname: $Hostname"
            Write-Verbose -Message "Supplied ExportFolder: `"$ExportFolder`""

            #region Authentication Token encryption
                $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($APIToken)
                $CleartextAPIToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            #endregion

            #region Backup encryption
                if($EncryptedBackupPassword){
                    try{
                        $BSTREnc = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($EncryptedBackupPassword)
                        $CleartextBackupPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTREnc)

                        if($CleartextBackupPassword){
                            Write-Verbose -Message "Backup encryption enabled with supplied passwor"
                            $encpwd = $true

                            $bodyvalue = '{"password":"' + $CleartextBackupPassword + '"}'
                        }
                        else{
                            Write-Verbose -Message "Failed to parse EncryptedBackupPassword, skipping backup encryption"
                            $encpwd = $false
                        }
                    }
                    catch{
                        Write-Verbose -Message "Failed to parse EncryptedBackupPassword, skipping backup encryption"
                        $encpwd = $false
                    }
                }
                else{
                    Write-Verbose -Message "No backup password supplied, skipping backup encryption"
                    $encpwd = $false
                }
            #endregion

            #region API Call encryption in body
                $InvokeRestMethodParams = @{
                    "Headers" = @{ "Authorization" = "Bearer $CleartextAPIToken" }
                    "Method" = "Post"
                    "ContentType" = 'application/json;charset=utf-8'
                    "ErrorAction" = "Stop"
                    "WarningAction" = "Stop"
                    "Verbose" = $false
                }

                #Add encryption password to body if used
                if($bodyvalue){ [void]$InvokeRestMethodParams.Add("Body",$bodyvalue) }

                $APIEndPoint = "https://$Hostname/api/v2/monitor/system/config/backup"
                $APIParameters = "?destination=file&scope=global"
                $APIFullUri = "{0}{1}" -f $APIEndPoint,$APIParameters

                #FNDN Documentation: https://fndn.fortinet.net/index.php?/fortiapi/1-fortios/2168/1/system/
                #destination: Configuration file destination [file* | usb]
                #scope: Specify global or VDOM only backup [global | vdom]
                #password: Password to encrypt configuration data.

                Write-Verbose -Message "API Uri: `"$APIFullUri`""
            #endregion

            <# DEBUG example
            $clearpwd = "blablabla"
            $bodycode = '{"password":"' + $clearpwd + '"}'

            Invoke-RestMethod `
                -Uri "https://fgt1.domain.com/api/v2/monitor/system/config/backup?destination=file&scope=global" `
                -Headers @{ "Authorization" = "Bearer BearerTokenClearTextHere" } `
                -Method Post `
                -Body $bodycode ` #<optional encoding>
                -ContentType 'application/json;charset=utf-8' `
                -ErrorAction Stop `
                -WarningAction Stop `
                -Verbose:$false
            #>

            try{
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                $backupContent = Invoke-RestMethod -Uri $APIFullUri @InvokeRestMethodParams
                
                #region Export config to file
                    if(!( [string]::IsNullOrEmpty($backupContent))){
                        Write-Verbose -Message "Successfully executed API call"
                        
                        $HostNameFileName = $Hostname -replace "\.$(($env:USERDNSDOMAIN).ToLower())$",""
                        $HostNameFileName = $HostNameFileName -Replace "[^a-z0-9-]",""
                        $HostNameFileName = "$HostNameFileName-$((Get-Date).ToString("yyyyMMdd-HHmm"))"

                        #region Adding filename suffix if encrypted
                            if($encpwd){
                                $encryptedfirstline = ($backupContent -split '\n')[0]
                                if($encryptedfirstline.length -lt 30 -and $encryptedfirstline -match "^#FGBK\|"){
                                    $encryptedfirstline = ($encryptedfirstline.Trim("#|")) -replace "\|","-"
                                    $HostNameFileName = "$HostNameFileName-$encryptedfirstline"
                                }
                            }
                        #endregion
                        
                        $FullExportPath = Join-Path -Path $ExportFolder -ChildPath "$($HostNameFileName).conf"

                        $backupContent | Out-File $FullExportPath -Encoding utf8 -Force -ErrorAction Stop

                        #region export logging
                            if(Test-Path -Path $FullExportPath){
                                Write-Verbose -Message "Exported FortiGate configuration to `"$FullExportPath`" ($([math]::Round((Get-Item $FullExportPath).Length/1KB))KB)"
                            }
                            else{
                                Write-Warning -Message "No backup configuration file created, something went wrong"
                            }
                        #endregion
                    }
                    else{
                        Write-Warning -Message "No output returned from Invoke-RestMethod, No backup taken!"
                    }
                #endregion
            }
            catch{
                if($_.Exception.Message -match "\(403\)"){$AddLog = "(Check API Profile access permissions or Trusted Hosts)"}
                else{$AddLog = ""}

                Write-Warning -Message "Error occurred while trying to backup FortiGate $Hostname. Exception: $($_.Exception.Message) $AddLog"
            }
        }
        else{
            Write-Warning -Message "ExportFolder `"$ExportFolder`" does not exist. No backup taken!"
        }
    }
    else{
        Write-Warning -Message "$Hostname is not responding on ICMP. No backup taken!"
    }
}
