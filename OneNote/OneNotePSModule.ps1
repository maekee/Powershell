# When running Connect-OneNote a new Com Object is initiated (ONENOTE.exe process started)
# If you try to start OneNote manually when this Com Object is established you will get
# a popup windows saying: "OneNote is cleaning up from the last time it was open" and then that OneNote cannot be opened.
# If you Disconnect the Com Object and start OneNote again, works fine.
# So there is a conflict between the Com Object process and the process started by the user

# To work around this, we can check that no ONENOTE.exe process is running before Connecting the Com Object.
# Then when we are done, we just run Disconnect-OneNote.

Function Connect-OneNote {
    [CmdletBinding()]
    param([switch]$Reload)

    if($PSBoundParameters.ContainsKey('Reload')){
        if(Get-Variable OneNote -ErrorAction SilentlyContinue){
            Remove-Variable -Name OneNote -Scope Global
            #Write-Verbose -Message "Removed OneNote variable"
        }
        else{
            #Write-Verbose -Message "OneNote variable not present"
        }
    }

    #Below logic checks that OneNote variable exists, is of correct type and the Windows Property is not empty (Com Object lost)
    if( $OneNote -and $OneNote.GetType().FullName -eq "Microsoft.Office.Interop.OneNote.Application2Class" -and $null -ne $OneNote.Windows){
        #Write-Verbose -Message "OneNote variable already present"
    }
    else{
        $VerbosePreference = "SilentlyContinue" 
        Add-Type -AssemblyName Microsoft.Office.Interop.OneNote -ErrorAction Stop
        $Global:OneNote = New-Object -ComObject OneNote.Application -ErrorAction Stop
        $VerbosePreference = "Continue"
        #Write-Verbose -Message "Created OneNote variable"
    }

    #Return variable status for validation
    if($OneNote -and $OneNote.GetType().FullName -eq "Microsoft.Office.Interop.OneNote.Application2Class"){$true}
    else{$false}
}
Function Disconnect-OneNote {
    if($OneNote){
        try{
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($OneNote) | Out-Null
            Remove-Variable OneNote -Scope Global -ErrorAction SilentlyContinue
        }
        catch{
            Write-Warning -Message "Error occurred while disconnecting (releasing) Com Object to OneNote"
        }
    }
}

Function Get-OneNoteNotebook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][string]$Identity
    )

    if((Connect-OneNote) -eq $false){Write-Warning "OneNote Class variable missing";break}
    
    if($PSBoundParameters.ContainsKey('Identity')){
        if($Identity -match "^{"){$IdentityType = "ID"}elseif($Identity -match "^http"){$IdentityType = "Path"}else{$IdentityType = "Name"}
        #Write-Verbose -Message "Using Identity type $IdentityType"
    }

    try{
        $Scope = [Microsoft.Office.Interop.OneNote.HierarchyScope]::hsNotebooks
        [xml]$Hierarchy = ""
        $OneNote.GetHierarchy("", [Microsoft.Office.InterOp.OneNote.HierarchyScope]::hsPages, [ref]$Hierarchy)

        if($PSBoundParameters.ContainsKey('Identity')){
            if($IdentityType -eq "ID"){
                $Hierarchy.Notebooks.Notebook | Where {$_.ID -eq $Identity} #| Select Name, path, ID, isUnread, isCurrentlyViewed
            }
            elseif($IdentityType -eq "Path"){
                $Hierarchy.Notebooks.Notebook | Where {$_.path -eq $Identity} #| Select Name, path, ID, isUnread, isCurrentlyViewed
            }
            elseif($IdentityType -eq "Name"){
                $Hierarchy.Notebooks.Notebook | Where {$_.name -eq $Identity -or $_.nickname -eq $Identity} #| Select Name, path, ID, isUnread, isCurrentlyViewed
            }
        }
        else{
            $Hierarchy.Notebooks.Notebook #| Select Name, path, ID, isUnread, isCurrentlyViewed
        }
    }
    catch{
        Write-Warning -Message "Error occurred while getting OneNote Notebooks. Exception: $($_.Exception.Message)"
    }
}

Function Close-OneNoteNotebook {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$NoteBookID)

    if((Connect-OneNote) -eq $false){Write-Warning "OneNote Class variable missing";break}

    #Check presence of Notebook
    $OneNoteNotebookObj = Get-OneNoteNotebook -Identity $NoteBookID
    if($OneNoteNotebookObj){
        Write-Verbose -Message "Found Notebook `"$($OneNoteNotebookObj.name)`" with ID `"$($OneNoteNotebookObj.ID)`""

        try{
            $OneNote.CloseNotebook($NoteBookID)
            Write-Verbose -Message "Successfully closed OneNote Notebook `"$($OneNoteNotebookObj.name)`" ($($OneNoteNotebookObj.nickname)) with ID `"$($OneNoteNotebookObj.ID)`""
        }
        catch{
            Write-Warning -Message "Failed to close OneNote Notebook `"$($OneNoteNotebookObj.name)`" ($($OneNoteNotebookObj.nickname)) with ID `"$($OneNoteNotebookObj.ID)`". Exception: $($_.Exception.Message)"
        }
    }
    else{
        Write-Warning -Message "Notebook with ID $NoteBookID not not found"
    }
}
Function Connect-OneNoteNotebook {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$NoteBookUrl)

    if((Connect-OneNote) -eq $false){Write-Warning -Message "OneNote Class variable missing";break}
    if($NoteBookUrl -notmatch "^https"){Write-Warning -Message "Only SharePoint OneNote Notebooks Url https paths is supported";break}

    try{
        $Scope = [Microsoft.Office.Interop.OneNote.HierarchyScope]::hsNotebooks
        [ref]$xml = ""
        $OneNote.OpenHierarchy($NoteBookUrl, "", $xml, "cftNotebook")
        Write-Verbose -Message "Successfully mounted OneNote Notebook $($NoteBookUrl)"
    }
    catch{
        Write-Warning -Message "Failed to connect OneNote Notebook from Url `"$($NoteBookUrl.name)`". Exception: $($_.Exception.Message)"
    }
}

Function Sync-OneNoteNotebook {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$NoteBookID)

    if((Connect-OneNote) -eq $false){Write-Warning "OneNote Class variable missing";break}

    #Check presence of Notebook
    $OneNoteNotebookObj = Get-OneNoteNotebook -Identity $NoteBookID
    if($OneNoteNotebookObj){
        Write-Verbose -Message "Found Notebook `"$($OneNoteNotebookObj.name)`" with ID `"$($OneNoteNotebookObj.ID)`""

        try{
            $OneNote.SyncHierarchy($NoteBookID)
            Write-Verbose -Message "Successfully triggered a Sync of OneNote Notebook `"$($OneNoteNotebookObj.name)`" ($($OneNoteNotebookObj.nickname)) with ID `"$($OneNoteNotebookObj.ID)`""
        }
        catch{
            Write-Warning -Message "Failed to sync Notebook `"$($OneNoteNotebookObj.name)`" ($($OneNoteNotebookObj.nickname)) with ID `"$($OneNoteNotebookObj.ID)`". Exception: $($_.Exception.Message)"
        }
    }
    else{
        Write-Warning -Message "Notebook with ID $NoteBookID not not found"
    }
}

Function Get-OneNoteVersion {
    $regKey = Get-Item -Path "HKCU:\Software\Microsoft\Office\16.0\OneNote\OpenNotebooks"
    if($regKey.Name -match "Office\\(\d\d\.\d)"){$Matches.1}
}

#Backup-OneNoteNotebook executes with asynchronous communication, so continues to happen in the background
Function Backup-OneNoteNotebook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][string]$Identity,
        [Parameter(Mandatory=$true)][string]$ExportFolder
    )

    if((Connect-OneNote) -eq $false){Write-Warning "OneNote Class variable missing";break}

    # Add subfolder with timestamp, if this is commented off onenote-backups are placed in ExportFolder
    $ExportFolder = Join-Path $ExportFolder -ChildPath $((Get-Date).ToString("yyyyMMdd-HHmmss"))

    if($PSBoundParameters.ContainsKey('Identity')){ $noteBookArray = @(Get-OneNoteNotebook -Identity $Identity) }
    else{ $noteBookArray = @(Get-OneNoteNotebook) }

    if($noteBookArray.Count -gt 0){
        #region Create exportfolder if missing
            try{
                if(!(Test-Path $ExportFolder)){ New-Item -Path $ExportFolder -ItemType Directory -Force | Out-Null }
            }
            catch{
                Write-Warning -Message "Error occurred while creating export folder $ExportFolder. Exception: $($_.exception.Message)"
                break
            }
        #endregion

        #region Backup OneNote Notebooks
            try{
                foreach($currOneNoteNoteBook in $noteBookArray){
                    Write-Verbose -Message "Backing up $($currOneNoteNoteBook.name).. this can take a while"

                    $currNotebookPath = Join-Path -Path $ExportFolder -ChildPath "$($currOneNoteNoteBook.name).onepkg"
                    $OneNote.Publish($currOneNoteNoteBook.ID, $currNotebookPath, 1) #1 = .onepkg
                }
            }
            catch{
                Write-Warning -Message "Error occurred while backing up OneNote Notebook $($currOneNoteNoteBook.name) to $ExportFolder. Exception: $($_.exception.Message)"
            }
        #endregion
    }
    else{
        Write-Verbose -Message "No OneNote notebook found"
    }
}
