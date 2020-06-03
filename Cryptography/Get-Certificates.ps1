 Function Get-Certificates{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, HelpMessage="CASERVER\CAName, run 'certutil -getconfig' on issuing CA to get Config string")]
        [ValidateNotNullOrEmpty()]
        [string]$CAlocation,
        [ValidateSet('IssuedCertificates','RevokedCertificates','PendingApproval')]
        [string]$DispositionType = 'IssuedCertificates',
        [string]$FilterByCommonName,
        [switch]$IncludeBinaryCertificate,
        [int]$ExpireInDays
    )

    $CaView = New-Object -Com CertificateAuthority.View.1
    
    [void]$CaView.OpenConnection($CAlocation)

    #region defining Columns
        $NumberOfColumns = 8

        if($IncludeBinaryCertificate){$NumberOfColumns++}

        $CaView.SetResultColumnCount($NumberOfColumns)

        $CommonNameAttr = $CAView.GetColumnIndex($False, "CommonName")
        $NotAfterAttr = $CAView.GetColumnIndex($False, "NotAfter")
        $DNAttr = $CAView.GetColumnIndex($False, "DistinguishedName")
        $DispositionAttr = $CAView.GetColumnIndex($False, "Disposition")
        $CertExpAttr = $CaView.GetColumnIndex($false, "Certificate Expiration Date")
        $CertEffecAttr = $CaView.GetColumnIndex($false, "Certificate Effective Date")
        $ReqIDAttr = $CaView.GetColumnIndex($false, "Request ID")
        $CertTempAttr = $CaView.GetColumnIndex($false, "Certificate Template")

        if($IncludeBinaryCertificate){ $RequesterNameAttr = $CaView.GetColumnIndex($false, "Binary Certificate") }

        $CommonNameAttr, $NotAfterAttr, $DNAttr, $DispositionAttr, $CertExpAttr, $CertEffecAttr, $ReqIDAttr, $CertTempAttr | Foreach{ $CAView.SetResultColumn($_) }

    #endregion

    #region CAView filters
        $CVR_SEEK_EQ = 1
        $CVR_SEEK_LT = 2
        $CVR_SEEK_GT = 16

        $DispositionHash = @{
            'IssuedCertificates' = 20
            'RevokedCertificates' = 21
            'PendingApproval' = 9
        }
        $DispositionValue = $DispositionHash.$DispositionType
        $CAView.SetRestriction($DispositionAttr,$CVR_SEEK_EQ,0,$DispositionValue)

        if($ExpireInDays){
            $Today = Get-Date
            $ExpirationDate = $Today.AddDays($ExpireInDays)
            $CAView.SetRestriction($CertExpAttr,$CVR_SEEK_GT,0,$Today)
            $CAView.SetRestriction($CertExpAttr,$CVR_SEEK_LT,0,$ExpirationDate)
        }
        if($FilterByCommonName){
            $CaView.SetRestriction($CommonNameAttr,$CVR_SEEK_EQ,0,$FilterByCommonName)
        }
    #endregion
 
    $RowObj= $CAView.OpenView()
    $CurrentList = New-Object System.Collections.ArrayList

    [void]$RowObj.Next()
 
    Do {
        try{
            $ColObj = $RowObj.EnumCertViewColumn()
            [void]$ColObj.Next()

            $propHash = @{}
 
            Do {
                try{
                    $ColName = $ColObj.GetDisplayName()
                    $ColValue = $ColObj.GetValue(1)
                    Write-Verbose "Attribute: $ColName, Value: $ColValue"
                    $propHash.$ColName = $ColValue
                }
                catch{
                    if($_.Exception.Message -match "You cannot call a method on a null-valued expression"){ Write-Warning "Nothing found" }
                    else{Write-Warning "Exception $($_.Exception.Message)"}
                }
            }
            Until ($ColObj.Next() -eq -1)
            Write-Verbose "-----------------------------"

            $NewObject = New-Object PSObject -Property $propHash
            [void]$CurrentList.Add($NewObject)
 
        }
        catch{ <#Write-Warning "Exception $($_.Exception.Message)"#>}
    }
    Until ($Rowobj.Next() -eq -1 )

    $CurrentList
} 
