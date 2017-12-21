#Here is yet two more CaesarCipher/Shift Cipher encrypt/decrypt functions

 Function ConvertTo-CaesarCipherText{
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$String,
        [Parameter(Mandatory=$true, Position=1)][int]$Shift = 3
    )

    $String.ToCharArray() | ForEach-Object {
        $CipherString += [char]([int]$_ + $Shift)
    }

    $CipherString
}
Function ConvertFrom-CaesarCipherText{
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$CipherText,
        [Parameter(Mandatory=$true, Position=1)][int]$Shift = 3
    )

    $CipherText.ToCharArray() | ForEach-Object {
        $ClearText += [char]([int]$_ - $Shift)
    }

    $ClearText
}
