## Very simple GUI popup for getting a value back to PowerShell

Function Get-GUIValue{
    [CmdletBinding()]
    param([string]$Title,[string]$Description)

    IF($PSVersionTable.PSVersion.Major -lt 2){ Write-Warning "Powershell v1 not supported";Break }
    IF(-NOT $Title){ $TitleValue = "Enter value in the textbox" }ELSE{$TitleValue = $Title}
    IF(-NOT $Description){$DescriptionValue = "Please enter the desired value in the textbox"}ELSE{$DescriptionValue = $Description}

    TRY{
        Add-Type -AssemblyName Microsoft.VisualBasic
        $ReturnedValue = $( [Microsoft.VisualBasic.Interaction]::InputBox($DescriptionValue,$TitleValue, "<enter here>") )
    }
    CATCH {Break}

    IF($ReturnedValue -eq '<enter here>'){$ReturnedValue = $null}
    return $ReturnedValue
}
