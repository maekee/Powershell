# This function parses the MSGTRK exchange log (not tested with MSGTRKMA, MSGTRKMD or MSGTRKMS)
# More details here: https://docs.microsoft.com/en-us/exchange/mail-flow/transport-logs/message-tracking?view=exchserver-2019

Function ConvertFrom-ExchMsgTrkLog{
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$MsgTrkRow)

    if($MsgTrkRow -notmatch "^\#"){
        $RegexOptions = [System.Text.RegularExpressions.RegexOptions]
        $csvSplitRegEx = '(,)(?=(?:[^"]|"[^"]*")*$)'
        $splitColumn = [regex]::Split($MsgTrkRow, $csvSplitRegEx, $RegexOptions::ExplicitCapture)

        $propHash = [Ordered]@{}
        $propHash.'date-time' = $splitColumn[0]
        $propHash.'client-ip' = $splitColumn[1]
        $propHash.'client-hostname' = $splitColumn[2]
        $propHash.'server-ip' = $splitColumn[3]
        $propHash.'server-hostname' = $splitColumn[4]
        $propHash.'source-context' = $splitColumn[5]
        $propHash.'connector-id' = $splitColumn[6]
        $propHash.'source' = $splitColumn[7]
        $propHash.'event-id' = $splitColumn[8]
        $propHash.'internal-message-id' = $splitColumn[9]
        $propHash.'message-id' = $splitColumn[10]
        $propHash.'network-message-id' = $splitColumn[11]
        $propHash.'recipient-address' = @($splitColumn[12] -split ";")
        $propHash.'recipient-status' = $splitColumn[13]
        $propHash.'total-bytes' = $splitColumn[14]
        $propHash.'recipient-count' = $splitColumn[15]
        $propHash.'related-recipient-address' = $splitColumn[16]
        $propHash.'reference' = $splitColumn[17]
        $propHash.'message-subject' = $splitColumn[18]
        $propHash.'sender-address' = $splitColumn[19]
        #$propHash.'return-path' = $splitColumn[20]
        $propHash.'message-info' = $splitColumn[21]
        $propHash.'directionality' = $splitColumn[22]
        $propHash.'tenant-id' = $splitColumn[23]
        $propHash.'original-client-ip' = $splitColumn[24]
        $propHash.'original-server-ip' = $splitColumn[25]
        #$propHash.'custom-data' = $splitColumn[26]
        $propHash.'transport-traffic-type' = $splitColumn[27]
        $propHash.'log-id' = $splitColumn[28]
        $propHash.'schema-version' = $splitColumn[29]

        New-Object PSObject -Property $propHash
    }
    else{
        Write-Verbose -Message "Line looks like a comment, skipping..."
    }
}
