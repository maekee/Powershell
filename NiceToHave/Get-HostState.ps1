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

    <#
    Online:
    # Nmap 7.92 scan initiated Thu Nov 18 11:33:11 2021 as: "C:\\Program Files (x86)\\Nmap\\nmap.exe" -sn -T5 -oG - 192.168.100.1
    Host: 192.168.100.1 (SERVERNAME.domain.com)	Status: Up
    # Nmap done at Thu Nov 18 11:33:11 2021 -- 1 IP address (1 host up) scanned in 0.06 seconds

    Offline:
    # Nmap 7.92 scan initiated Thu Nov 18 11:38:01 2021 as: "C:\\Program Files (x86)\\Nmap\\nmap.exe" -sn -T5 -oG - 192.168.100.1
    # Nmap done at Thu Nov 18 11:38:03 2021 -- 1 IP address (0 hosts up) scanned in 1.55 seconds
    #>

    if($output.nmaprun.runstats.hosts.up -eq 1){$true}
    elseif($output.nmaprun.runstats.hosts.down -eq 1){$false}
    else{Write-Warning -Message "Neither up or down!? $(($output.nmaprun.runstats.hosts | Select @{Name="Hosts";expression={"up $($_.up), down $($_.down), total $($_.total)"}}).Hosts)"}
}
