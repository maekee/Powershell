# How to store sensitive data in powershell variables
$CleartextAPIKey = Read-Host -AsSecureString <# via prompt #>

# How to store password in username/password as encrypted string (username is cleartext)
$UserNamePassworCredentials = Get-Credentials

# How to save sensitive variable content to file as encrypted standard string
$CleartextAPIKey | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Out-File "C:\SecureSTring\securekey.txt" -Force 

#How to get the encrypted secure string data from disk back into variable
$EncryptedAPIKey = Get-Content "C:\SecureSTring\securekey.txt" | ConvertTo-SecureString
$BSTREnc = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($EncryptedAPIKey)
$CleartextAPIKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTREnc) 

# Here is how you read the securekey and build a PS CredentialsObject
$Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "Admin", (Get-Content "C:\SecureString\securekey.txt" | ConvertTo-SecureString)
