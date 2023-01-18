Enum and Enum with flags can be pretty nice, it declares Types that simplify the code.

enum LogonTypes {
	Interactive = 2
	Network = 3
	Batch = 4
	Service = 5
	Unlock = 7
	NetworkClearText = 8
	NewCredentials = 9
	RemoteInteractive = 10
	CachedInteractive = 11
}

# [LogonTypes]2 results in "Interactive"
# So we do not need to use arrays, arraylists or hashtables to map, but have in mind that we throw exceptions if entry is missing.

# [LogonTypes].GetEnumNames() lists names

#If you add multiple enums, the values add up and result in a new entry.
[LogonTypes]$result = [LogonTypes]::Interactive
[LogonTypes]$result += [LogonTypes]::Network
#[LogonTypes]$result will become 2+3 = "Service"

#If the requirement is to have multiple entries, you have to switch to flags

[Flags()] enum Binary {
    Bit1 = 1
    Bit2 = 2
    Bit3 = 4
    Bit4 = 8
    Bit5 = 16
    Bit6 = 32
    Bit7 = 64
    Bit8 = 128
}

[Binary]$number = [Binary]::Bit1
[Binary]$number += [Binary]::Bit2
# $number results in "Bit1 Bit2"

#[Binary]5 results in Bit1 Bit3

#if $number contains Bit1, Bit2 (-band below : Binary comparison operator)
($number -band [Binary]::Bit1) -eq [Binary]::Bit1 #results in true
($number -band [Binary]::Bit4) -eq [Binary]::Bit4 #results in $false

# Read more
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_enum?view=powershell-7.3
