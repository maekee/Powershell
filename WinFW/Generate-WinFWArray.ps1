# This function parses the Windows Firewall Log, creates an array with objects in which you can filter and search.
# Created this to help out colleagues that need an overview of traffic coming in to the WinFW.

# Elevation is required to read WinFW logfiles!

# If no LogPath parameter is supplied, the script will look in the registry for the Windows Firewall Log path
# If logging is enabled per profile the default location is C:\WINDOWS\system32\LogFiles\Firewall
# The Generate-WinFWArray defaults to the domain profile logfile

# So make sure logging is enabled per Windows Firewall profile (domain, private, public)
# Sorry about the missing comment based help.

Function Generate-WinFWArray{
    [CmdletBinding()]
    param(
        [string]$LogPath,
        [switch]$OnlyIncomingTraffic,
        [switch]$OnlyDenyTraffic
    )

    if($LogPath){
        if(Test-Path $LogPath){$WinFWLogPath = $logpath}
        else{ Write-Warning "`"$LogPath`" not found" }
    }
    else{
        try{
            $RegistryPath = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile\Logging" -ErrorAction Stop).LogFilePath
            if($RegistryPath){ $WinFWLogPath = $RegistryPath }
            else{ Write-Warning "Registry Windows Firewall log path autodetect failed." }
        }
        catch {
            Write-Warning "Registry Windows Firewall log path autodetect failed."
        }
    }

    if($WinFWLogPath){
        $resultList = New-Object System.Collections.ArrayList

        $FWLogContent = Get-Content $WinFWLogPath

        if($OnlyIncomingTraffic){
            Write-Verbose "Only Incoming (receive) log entrys"
            $FWLogContent = $FWLogContent | Where {$_ -match "RECEIVE" }
        }

        if($OnlyDenyTraffic){
            Write-Verbose "Only Deny log entrys"
            $FWLogContent = $FWLogContent | Where {$_ -match "DROP" }
        }

        if(!($OnlyIncomingTraffic -or $OnlyDenyTraffic)){
            Write-Verbose "No comments or empty lines"
            $FWLogContent = $FWLogContent | Where {$_ -notmatch "^#" -AND $_ -ne ""}
        }

        $i = 0
        foreach($row in $FWLogContent){
            Write-Progress "Building array from $($FWLogContent.Count) entrys" "$([Math]::Round($($i/$FWLogContent.Count*100))) % Complete:" -PercentComplete $($i/$FWLogContent.Count*100)
            $allEntrys = $row.split(' ')
            $currentObj = New-Object PSObject -Property @{
                "Date" = $allEntrys[0]
                "Time" = $allEntrys[1]
                "DateObj" = Get-Date "$($allEntrys[0]) $($allEntrys[1])"
                "Action" = $allEntrys[2]
                "Protocol" = $allEntrys[3]
                "Source_IP" = $allEntrys[4]
                "Dest_IP" = $allEntrys[5]
                "Source_Port" = $allEntrys[6]
                "Dest_Port" = $allEntrys[7]
                "Size" = $allEntrys[8]
                "TcpFlags" = $allEntrys[9]
                "TcpSyn" = $allEntrys[10]
                "TcpAck" = $allEntrys[11]
                "TcpWin" = $allEntrys[12]
                "IcmpType" = $allEntrys[13]
                "Icmpcode" = $allEntrys[14]
                "Info" = $allEntrys[15]
                "Path" = $allEntrys[16]
            }
            [void]$resultList.Add($currentObj)
            $i++
        }

        $resultList | Sort DateObj | Select "Date","Time","DateObj","Action","Protocol","Source_IP","Dest_IP","Source_Port","Dest_Port","Size","TcpFlags","TcpSyn","TcpAck","TcpWin","IcmpType","Icmpcode","Info","Path"
        Write-Verbose "Collected $($resultList.Count) entrys"
        if($resultList.Count -gt 1){Write-Verbose "Oldest Entry: $($resultList[0].DateObj.ToString("yyyy-MM-dd HH:mm:ss"))"}
    }
}

#Example
$WinFWArrayList = Generate-WinFWArray -OnlyIncomingTraffic -Verbose

$WinFWArrayList | Where {
    $_."Dest_IP" -notmatch "^224.0" -AND
    $_."Dest_IP" -ne "ff02::c" -AND
    $_."Dest_IP" -ne "ff02::fb" -AND
    $_."Dest_IP" -ne "::1" -AND
    $_."Protocol" -ne "ICMP" -AND
    $_."Dest_Port" -notmatch "3389|5355|1900|3702|5358|5357|2869|3702" -AND #RDP (3389), Network Discovery Ports
    $_."Dest_Port" -notmatch "5985|5986" #PowerShell Remoting
} | Group-Object "Dest_Port" | `
        Select Count,
        @{name="Port";expression={ $_.Name }},
        @{name="Protocol";expression={ ($_.Group | Select "Protocol" -ExpandProperty "Protocol" | Group-Object | Select Count,Name | Sort Count -Descending).Name -join "," }},
        @{name="Action";expression={ ($_.Group | Select "Action" -ExpandProperty "Action" | Group-Object | Select Count,Name | Sort Count -Descending).Name -join "," }},
        @{name="Source_IP";expression={ $_.Group | Select "Source_IP" -ExpandProperty "Source_IP" | Group-Object | Select Count,Name | Sort Count -Descending }},
        Group | Sort Count -Descending | ft -AutoSize
