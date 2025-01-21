# These are two ways to enable popup windows, a third is Forms. I will not go into forms because that is much more flexible, i just needed a msgbox.

# The first way is with [System.Windows.MessageBox]::Show
# Pros is more flexible with icons and buttons, con is can be placed behind other windows
# You can replace the ValidateSets and point directly to the .NET Enums, but i needed to call the script where this way did not work. So i hardcoded the ones i wanted to use

Function New-WindowsPopup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)][ValidateNotNullOrEmpty()]$Text,
        [Parameter(Mandatory=$false, Position=1)]$Title = "Information",
        [Parameter(Mandatory=$false, Position=2)][ValidateSet('None','Hand','Error','Stop','Question','Exclamation','Warning','Asterisk','Information')][string]$Image = "Information",
        [Parameter(Mandatory=$false, Position=3)][ValidateSet('OK','OKCancel','YesNoCancel','YesNo')][string]$ButtonStyle = "OK"
    )

    Add-Type -AssemblyName PresentationCore,PresentationFramework
    [System.Windows.MessageBox]::Show($Text,$Title,$ButtonStyle,$Image)
}

# Second way is to use [Microsoft.VisualBasic.Interaction]::MsgBox
# Pros, places message in focus, cons is not as customizable as [System.Windows.MessageBox]::Show
# This method uses a predefined MsgBoxStyle object, can be listed with:
# [Microsoft.VisualBasic.MsgBoxStyle].GetEnumNames()

#Then used like this

Function New-WindowsPopup {
    param(
        [Parameter(Mandatory=$true, Position=0)][ValidateNotNullOrEmpty()]$Text,
        [Parameter(Mandatory=$false, Position=1)]$Title = "Information",
        [Parameter(Mandatory=$false, Position=3)][ValidateSet('OkOnly','OKCancel','YesNoCancel','YesNo','Critical','Question','Exclamation','Information','MsgBoxHelp')][string]$MessageStyle = "OK"
    )


    Add-Type -AssemblyName Microsoft.VisualBasic
    [Microsoft.VisualBasic.Interaction]::MsgBox($Text, $([Microsoft.VisualBasic.MsgBoxStyle]::$($MessageStyle)), $Title)
}
