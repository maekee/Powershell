Function New-PacketCapture {
<#
    .SYNOPSIS
    Creates a Microsoft Event Trace log file (etl)

    .DESCRIPTION
    Creates a Microsoft Event Trace log file (etl) for the duration of the time specified in the parameter CaptureSeconds.
    The function is "just" a wrapper where the star of the show is "netsh trace", but added additional flexibility of PowerShell

    .PARAMETER CaptureSeconds
    Parameter to specify how long the trace should last

    .PARAMETER LocalIPAddress
    Parameter to specify IP address of the interface to capture from

    .PARAMETER TraceFileDestination
    Parameter to specify which directory to save the trace file

    .EXAMPLE
    New-PacketCapture -CaptureSeconds 15 -TraceFileDestination d:\tracelogs
    Starts a trace log, waits for 15 seconds and then stops the trace and save the trace to d:\tracelogs

    .NOTES
    You can convert the etl file to pcap file with tools available online
    
    A tool like this is: https://github.com/microsoft/etl2pcapng)
    (./etl2pcapng.exe d:\tracelogs\capture001.etl d:\tracelogs\capture001.pcap)

    This is the core code that does it all, everything around it is fluff:
      netsh trace start capture=yes IPv4.Address=192.168.1.10 tracefile=c:\temp\capture.etl
      Start-Sleep 90
      netsh trace stop

    Author:      @mickesunkan
    Github:      https://github.com/maekee/Powershell
    Version:     v1.0 (2022-11-29)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][ValidateRange(5,300)]$CaptureSeconds = 30,
        [Parameter(Mandatory=$false)]$LocalIPAddress,
        [Parameter(Mandatory=$true)]$TraceFileDestination
    )

    #region No IP address supplied 
        if(!($LocalIPAddress)){
            Write-Verbose -Message "No IP address supplied, getting local IPv4 address..."
        
            $LocalIPAddress = [array](Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -ne "Disconnected" }).IPv4Address.IPAddress
            if($LocalIPAddress.Count -eq 1){
                $LocalIPAddress = $LocalIPAddress[0]
                Write-Verbose -Message "Found local IP address $LocalIPAddress"
            }
            else{
                Write-Warning -Message "Multiple IP addresses detected: $($LocalIPAddress -join ", "), capture aborted"
                $LocalIPAddress = $null
            }
        }
        else{
            #region IP address logging
                if($null -ne $LocalIPAddress -and $LocalIPAddress -match "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$"){
                    Write-Verbose -Message "Using supplied IP address $LocalIPAddress"
                }
            #endregion
        }
    #endregion

    #region Continue with trace
        if($null -ne $LocalIPAddress -and $LocalIPAddress -match "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$"){
            #LocalIPAddress exists and looks like an IP address (dumb regex)
            Write-Verbose -Message "Running capture for $CaptureSeconds seconds"
        }
        else{
            else{
                Write-Warning -Message "Check IP address `"$LocalIPAddress`" and try again"
            }
        }

        #region Check if elevated
            if(([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){
                $elevated = $true
            }
            else{
                $elevated = $false
            }
        #endregion

        if(Test-Path -Path $TraceFileDestination){
            if($elevated -eq $true){
                $CaptureFileName = "trace_{0}_{1}_{2}-sec.etl" -f $(($LocalIPAddress -replace "[\.]","-").Trim()),$((Get-Date).ToString("yyMMddHHmm")),$CaptureSeconds
                $FullTracePath = $(Join-Path $TraceFileDestination $CaptureFileName)
            
                Write-Verbose -Message "Using trace file destination folder `"$FullTracePath`""
                Write-Verbose -Message "Starting trace between $((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")) and $(((Get-Date).AddSeconds($CaptureSeconds)).ToString("yyyy-MM-dd HH:mm:ss"))"
            
                try{
                    Write-Verbose -Message "Trace started"
                    netsh trace start capture=yes IPv4.Address=$LocalIPAddress tracefile=$FullTracePath

                    Start-Sleep $CaptureSeconds

                    Write-Verbose -Message "Trace stopped"
                    netsh trace stop
                }
                catch{
                    Write-Warning -Message "Error occurred while capturing trace to `"$FullTracePath`""
                }

                Write-Verbose -Message "Trace saved to `"$FullTracePath`" ($((Get-Item $FullTracePath).Length/1MB)MB)"
            }
            else{
                Write-Warning -Message "Capturing trace log requires elevated privileges, elevate process and try again"
            }
        }
        else{
            Write-Warning -Message "Trace file destination path `"$($TraceFileDestination)`" not found"
        }
    #endregion
}
