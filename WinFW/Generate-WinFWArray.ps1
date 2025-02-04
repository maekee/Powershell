# This function parses the Windows Firewall Log, creates an array with objects in which you can filter and search.
# Created this to help out colleagues that need an overview of traffic coming in to the WinFW.

# This is version 2, more filter functionality pre building objects

# Elevation is required to read WinFW logfiles!

# So make sure logging is enabled per Windows Firewall profile (domain, private, public)
# Sorry about the missing comment based help.

Function Generate-WinFWArray{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$LogPath,
        [ValidateSet('All','OutboundOnly','InboundOnly')][string]$FilterDirection = "All",
        [ValidateSet('All','TCP','UDP','ICMP')][string]$FilterProtocol = "All",
        [ValidateSet('All','DROP','ALLOW')][string]$FilterAction = "All",
        [switch]$SkipMulticast
    )

    if(Test-Path $LogPath){ $WinFWLogPath = $LogPath }
    else{ Write-Warning "`"$LogPath`" not found" }

    if($WinFWLogPath){
        $resultList = New-Object System.Collections.ArrayList

        $FWLogContent = Get-Content $WinFWLogPath

        if($FilterDirection -eq "OutboundOnly"){ $FWLogContent = $FWLogContent | Where {$_ -match "SEND" }}
        if($FilterDirection -eq "InboundOnly"){ $FWLogContent = $FWLogContent | Where {$_ -match "RECEIVE" }}

        if($FilterProtocol -eq "TCP"){ $FWLogContent = $FWLogContent | Where {$_ -match "TCP" }}
        if($FilterProtocol -eq "UDP"){ $FWLogContent = $FWLogContent | Where {$_ -match "UDP" }}
        if($FilterProtocol -eq "ICMP"){ $FWLogContent = $FWLogContent | Where {$_ -match "ICMP" }}

        if($FilterAction -eq "DROP"){ $FWLogContent = $FWLogContent | Where {$_ -match "DROP" }}
        if($FilterAction -eq "ALLOW"){ $FWLogContent = $FWLogContent | Where {$_ -match "ALLOW" }}

        if($SkipMulticast){ $FWLogContent = $FWLogContent | Where {
            $_ -notmatch "239\.255\.255\.250" -and
            $_ -notmatch "255\.255\.255\.255" -and
            $_ -notmatch "224\.0\.0\.22"
        }}

        $FWLogContent = $FWLogContent | Where {$_ -notmatch "^#" -AND $_ -ne ""}

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
