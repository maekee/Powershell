 Function Test-Port{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)][string[]]$DestinationIP,
        [Parameter(Mandatory=$true, Position=1)][int]$Port,
        [ValidateSet('TCP','UDP')]$Protocol = 'TCP'
    )

    Begin{ [System.Collections.ArrayList]$Results = @{} }
    Process{

        foreach ($CurrentIP in $DestinationIP){
            if($Protocol -eq 'TCP'){ $socket = New-Object -TypeName Net.Sockets.TCPClient }
            else{ $socket = New-Object -TypeName Net.Sockets.UDPClient }
        
            try{ $socket.Connect($CurrentIP, $Port) }
            catch { Write-Verbose "Exception: $($_.Exception.message)" }

            if($socket.Connected){ $Result = $true }else{ $Result = $false}
        
            $socket.Close()
            $socket = $null

            $StatusObj = [PSCustomObject]@{DestinationIP = $CurrentIP;Result = $Result}

            $Results.Add($StatusObj) | Out-Null
        }

    }
    End{ $Results }
} 

#Update 7/3 2018
#You can also use cmdlet Test-NetConnection if you want to test TCP and have that cmdlet available:
#https://docs.microsoft.com/en-us/powershell/module/nettcpip/test-netconnection?view=win10-ps
