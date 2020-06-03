#Just wrote up a small function based on code i found online.
#This code can probably be extended to support jpg/png and choose custom screen coordinates.

Function New-BitmapScreenshot{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)][string]$Path = (Get-Location).Path
    )
    
    #region Figure out if Path is Folder or file
        #region Path ends .2-4 letter extension, for example .bmp
            if( $Path -match "\.\w{2,4}$" ){
                $ChosenFileName = Split-Path -Path $Path -Leaf
                $ChosenFolder = Split-Path -Path $Path -Parent
                if($ChosenFolder -eq '.'){$ChosenFolder = (Get-Location).Path} #fixes .\file.jpg paths, but not deeper
                Write-Verbose "Detected folder `"$ChosenFolder`" and filename `"$ChosenFileName`" in `"$Path`""
            }
            else{
                $ChosenFolder = $Path
                Write-Verbose "Detected folder path `"$ChosenFolder`""
            }
        #endregion
        #region Create Folder if needed
            if(!(Test-Path -Path $ChosenFolder)){
                Write-Verbose "Path `"$ChosenFolder`" not found, creating it"
                New-Item $ChosenFolder -ItemType Directory | Out-Null
            }
        #endregion
    #endregion
    
    #region Generate Paths
        if(!($ChosenFileName)){ $ChosenFileName = "$env:COMPUTERNAME-$(Get-Date -f yyyy-MM-dd_HHmmss).bmp" }
        $FullPath = Join-Path $ChosenFolder $ChosenFileName
        Write-Verbose "Exporting bitmap screenshot to $FullPath"
    #endregion

    #region Load Assemblys and declare coordinate variables and objects
        try{
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
            Add-type -AssemblyName System.Drawing -ErrorAction Stop

            # Gather Screen resolution information
            $Screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
            $Width = $Screen.Width
            $Height = $Screen.Height
            $Left = $Screen.Left
            $Top = $Screen.Top
            Write-Verbose "Width: $Width"
            Write-Verbose "Heigth: $Height"
            Write-Verbose "Left: $Left"
            Write-Verbose "Top: $Top"

            # Create bitmap using the top-left and bottom-right bounds
            $bitmap = New-Object System.Drawing.Bitmap $Width, $Height -ErrorAction Stop

            # Create Graphics object
            $graphic = [System.Drawing.Graphics]::FromImage($bitmap)

            # Capture screen
            $graphic.CopyFromScreen($Left, $Top, 0, 0, $bitmap.Size)

            # Save to file
            $bitmap.Save($FullPath)

            Write-Output "Screenshot saved to `"$FullPath`""
        }
        catch{
            Write-Warning "Error occurred while saving bitmap screenshot. Exception:$($_.Exception.Message)"
        }
    #endregion
}
