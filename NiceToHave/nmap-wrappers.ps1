Function Get-HostState{
<#
.SYNOPSIS
    Gets up/down state on remote host
.DESCRIPTION
    Uses Nmap to see if a remote ip address is up or down
.PARAMETER IPaddress
    IP address of remote host
.PARAMETER NmapPath
    Optional parameter to be able to supply a nmap path if nmap is not found in PATH environment variable
.EXAMPLE
    Get-HostState -IPaddress 192.168.100.1
    Results in a True or False
.NOTES
    Script name: Get-HostState
    Twitter:     @mickesunkan
    Github:      https://github.com/maekee/Powershell

    When running this in Windows i got an exception when runnning nmap with error "Failed to open device eth0"
    Uninstalled Wireshark/npcap and this solved my problem.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$IPaddress,
        [Parameter(Mandatory=$false,HelpMessage="Nmap exe path if not found in path variable")]$NmapPath
    )

    if($PSBoundParameters.ContainsKey('nmapPath')){$nmap = "`"$nmapPath`""}
    else{$nmap = "nmap"}
    #we could check if nmap is found by adding: Get-Command nmap -ErrorAction SilentlyContinue

    [xml]$output = Invoke-Expression -Command ". $nmap $IPaddress -sn -T5 -oX -"

    #-sn:   No port scan
    #-T5:   Timing template T5 "Insane"
    #-oX -: XML output to stdout

    Write-Verbose -Message "Full Nmap command executed: $($output.nmaprun.args)"
    Write-Verbose -Message "Nmap result: $($output.nmaprun.runstats.finished.summary)"
    Write-Verbose -Message "Resolved name: $($output.nmaprun.host.hostnames.hostname.name)"

    if($output.nmaprun.runstats.hosts.up -eq 1){$true}
    elseif($output.nmaprun.runstats.hosts.down -eq 1){$false}
    else{Write-Warning -Message "Neither up or down!? $(($output.nmaprun.runstats.hosts | Select @{Name="Hosts";expression={"up $($_.up), down $($_.down), total $($_.total)"}}).Hosts)"}
}

Function Start-NetworkSweep{
<#
.SYNOPSIS
    Gets up/down states on hosts in remote network (sweep)
.DESCRIPTION
    Uses Nmap to find all remote ip addresses in network is up or down
.PARAMETER IPRange
    IP network address or IP network range (e.g 192.168.100.1-254 or 192.168.100.0/24)
.PARAMETER NmapPath
    Optional parameter to be able to supply a nmap path if nmap is not found in PATH environment variable
.EXAMPLE
    Start-NetworkSweep -IPRange 192.168.100.1-100
    Sweeps the first 100 addresses in the 192.168.100.0 network
.NOTES
    Script name: Start-NetworkSweep
    Twitter:     @mickesunkan
    Github:      https://github.com/maekee/Powershell
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,HelpMessage="Defines range e.g 192.168.100.1-254 or 192.168.100.0/24")]$IPRange,
        [Parameter(Mandatory=$false,HelpMessage="Nmap exe path if not found in path variable")]$NmapPath
    )

    if($PSBoundParameters.ContainsKey('nmapPath')){$nmap = "`"$nmapPath`""}
    else{$nmap = "nmap"}
    #we could check if nmap is found by adding: Get-Command nmap -ErrorAction SilentlyContinue

    [xml]$sweepoutput = Invoke-Expression -Command ". $nmap $IPRange -sn -T4 -oX -"

    #-sn:   No port scan
    #-T5:   Timing template T5 "Insane"
    #-oX -: XML output to stdout

    #-v: adds nodes with Status: down

    Write-Verbose -Message "Full Nmap command executed: $($sweepoutput.nmaprun.args)"
    Write-Verbose -Message "$($sweepoutput.nmaprun.runstats.finished.summary)"

    $sweepoutput.nmaprun.host | `
        Select  @{Name="State";expression={$_.status.state}},
                @{Name="Address";expression={ ([xml]$_.OuterXml).Host.address.addr }},
                @{Name="Name";expression={$_.hostnames.hostname.name}}
}
