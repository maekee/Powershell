Function Remove-StringLatinCharacters{
    param( [parameter(ValueFromPipeline = $true)][string]$String )

    Process{ [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($String)) }
}

Function Remove-StringDiacritic {
    param($String)

    $Normalized = $String.Normalize('FormD')

    $NewString = New-Object -TypeName System.Text.StringBuilder

    $Normalized.ToCharArray() | foreach {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($psitem) -ne [Globalization.UnicodeCategory]::NonSpacingMark){ [void]$NewString.Append($psitem) }
    }

    $NewString -as [string]
}
