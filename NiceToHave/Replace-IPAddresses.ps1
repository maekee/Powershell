#Small function to find ip addresses and replace with your own value

Function Replace-IPAddresses{
    [CmdletBinding()]
    param( $Path,$NewFilePath )

    $regExPattern = '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'

    $PathContent = Get-Content $Path
    $newFileContent = $PathContent
    
    $IPHits = [regex]::Matches($PathContent,$regExPattern).value
    $UniqueHits = $IPHits | Sort | Select -Unique

    $UniqueHits | Foreach {
        $IPReplacement = Read-Host "What value do you want to replace `"$($_)`" with?"
        $newFileContent = $newFileContent.Replace($_,$IPReplacement)
    }

    $newFileContent | Foreach { Write-Verbose $_ }
    $newFileContent | Out-File $NewFilePath -Encoding utf8
}
