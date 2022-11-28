Function Get-FortiGateHA{
<#
    .SYNOPSIS
    Gets HA (High-Availability) information from the cluster

    .DESCRIPTION
    Retrieves different kinds of HA aspects from the FortiGate cluster, depending on HAInformation parameter

    .PARAMETER APIToken
    Parameter to specify the FortiGate REST API token generated on the FortiGate.

    .PARAMETER Hostname
    Parameter to specify the hostname/FQDN of the FortiGate device (must match certificate CN/SAN-names used on device)

    .PARAMETER HAInformation
    HA information aspect to fetch from the FortiGate
    - PeerInfo: Get configuration of peer(s) in HA cluster. Uptime is expressed in seconds
    - Statistics: List of statistics for members of HA cluster
    - History: Get HA cluster historical logs
    - Checksums: List of checksums for members of HA cluster
    - HWInterface: Get HA NPU hardware interface status

    .EXAMPLE
    Get-FortiGateHA -APIToken $SecureStringToken -Hostname "fgt1.domain.com" -HAInformation History
    Gets statistics for members of HA cluster and authenticates with API token in variable $SecureStringToken

    .NOTES
    Script uses Tls1.2 for .NET FW

    Necessary read API Profile access permissions needs to be in place for API call
    Read-only administrator should be sufficient

    Known issue: Diacritics will be displayed incorrectly (Encoding issue with Invoke-RestMethod in PS 5.1)
    Author:      @mickesunkan
    Github:      https://github.com/maekee/Powershell
    Version:     v1.0 (2022-11-28)
    #>
    param(
        [Parameter(Mandatory=$true)][System.Security.SecureString]$APIToken,
        [Parameter(Mandatory=$true)]$Hostname,
        [Parameter(Mandatory=$false)][ValidateSet('PeerInfo','Statistics','History','Checksums','HWInterface')]$HAInformation = "PeerInfo"
    )

    $HAMapping = @{
        "PeerInfo" = "ha-peer" #Get configuration of peer(s) in HA cluster. Uptime is expressed in seconds
        "Statistics" = "ha-statistics" #List of statistics for members of HA cluster
        "History" = "ha-history" #Get HA cluster historical logs
        "Checksums" = "ha-checksums" #List of checksums for members of HA cluster
        "HWInterface" = "ha-hw-interface" #Get HA NPU hardware interface status
    }

    if(Test-Connection $Hostname -Count 1 -ErrorAction SilentlyContinue){

        #region Authentication Token encryption
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($APIToken)
            $CleartextAPIToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        #endregion

        #region API Call encryption in body
            $InvokeRestMethodParams = @{
                "Headers" = @{ "Authorization" = "Bearer $CleartextAPIToken" }
                "Method" = "Get"
                "ContentType" = 'application/json;charset=utf-8'
                "ErrorAction" = "Stop"
                "WarningAction" = "Stop"
                "Verbose" = $false
            }

            $APIEndPoint = "https://$Hostname/api/v2/monitor/system/$($HAMapping.$HAInformation)"
            $APIParameters = ""
            $APIFullUri = "{0}{1}" -f $APIEndPoint,$APIParameters

            #FNDN Documentation: https://fndn.fortinet.net/index.php?/fortiapi/1-fortios/2168/1/system/

            Write-Verbose -Message "API Uri: `"$APIFullUri`""
        #endregion

        <# DEBUG example
        $ClearTextApiToken = "blablabla"

        Invoke-RestMethod `
            -Uri "https://fgt1.domain.com/api/v2/monitor/system/ha-peer" `
            -Headers @{ "Authorization" = "Bearer $ClearTextApiToken" } `
            -Method Get `
            -ContentType 'application/json;charset=utf-8' `
            -ErrorAction Stop `
            -WarningAction Stop `
            -Verbose:$false
        #>

        try{
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-RestMethod -Uri $APIFullUri @InvokeRestMethodParams
        }
        catch{
            if($_.Exception.Message -match "\(403\)"){$AddLog = "(Check API Profile access permissions or Trusted Hosts)"}
            else{$AddLog = ""}

            Write-Warning -Message "Error occurred while trying to get FortiGate $Hostname HA $HAInformation. Exception: $($_.Exception.Message) $AddLog"
        }
    }
    else{
        Write-Warning -Message "$Hostname is not responding on ICMP. No backup taken!"
    }

}
