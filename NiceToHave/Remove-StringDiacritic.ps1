Function Remove-StringDiacritic {
    param([string]$String)

    $Normalized = $String.Normalize('FormD')
    $NewString = New-Object -TypeName System.Text.StringBuilder

    $Normalized.ToCharArray() | foreach {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($psitem) -ne [Globalization.UnicodeCategory]::NonSpacingMark){ [void]$NewString.Append($psitem) }
    }

    $NewString -as [string]
}
