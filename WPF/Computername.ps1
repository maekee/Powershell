# Fun little WPF (Windows Presentation Framework) GUI app

Add-Type -AssemblyName PresentationFramework

[xml]$Form = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="ComputerName" Height="150" Width="220" ResizeMode = "NoResize">
    <StackPanel Name="StackPanel1" Background="LightBlue" Orientation="Vertical" Margin="5,5,5,5">
        <Button Name="Start"
            Margin="0,20,0,0"
            Height="32"
            Width="140"
            Content="Get ComputerName">
        </Button>

        <Label Name="Label1"
            HorizontalContentAlignment="Center"
            Margin="0,10,0,0"
            FontWeight = "Bold"
            Width="140"
            Content="">
        </Label>

        <Label Name="Label2"
            HorizontalContentAlignment="Center"
            Margin="0,0,0,0"
            Width="200"
            FontSize="8"
            Content="Shift for UPPER CASE. Control for Capitalized case"/>

    </StackPanel>
</Window>
"@

$NR = (New-Object System.Xml.XmlNodeReader $Form)
$Win = [Windows.Markup.XamlReader]::Load( $NR ) 

$StartButton = $Win.FindName("Start")
$Label = $Win.FindName("Label1")

$StartButton.Add_Click({
    
    $IsShiftPressed = ([System.Windows.Input.Keyboard]::Modifiers -band [System.Windows.Input.ModifierKeys]::Shift)
    $IsControlPressed = ([System.Windows.Input.Keyboard]::Modifiers -band [System.Windows.Input.ModifierKeys]::Control)

    # Uppercase if Shift pressed
    if($IsShiftPressed){
        $Label.Content = ($env:COMPUTERNAME).ToUpper()
    }
    else{
        $Label.Content = ($env:COMPUTERNAME).ToLower()
    }
        
    # Capitalize
    if($IsControlPressed){
        $string = ($env:COMPUTERNAME).ToLower()
        $textInfo = (Get-Culture).TextInfo
        $capitalized = $textInfo.ToTitleCase($string)
        $Label.Content = $capitalized
    }
})

$Win.ShowDialog() #Always at the bottom
