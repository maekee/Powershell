Function Get-StringHash { 
    param(
        [Parameter(Mandatory=$true)][String]$String,
        [ValidateSet('MD5','SHA1','SHA256','SHA384','SHA512','RIPEMD160')]$HashAlgorithm = 'MD5'
    )
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($String)
    $algorithm = [System.Security.Cryptography.HashAlgorithm]::Create($HashAlgorithm)
    $StringBuilder = New-Object System.Text.StringBuilder 
  
    $algorithm.ComputeHash($bytes) | 
    ForEach-Object { [void]$StringBuilder.Append($_.ToString("x2")) } 
  
    New-Object PSObject -Property @{String = $String;HashAlgorithm = $HashAlgorithm;HashValue = $StringBuilder.ToString()}
}
