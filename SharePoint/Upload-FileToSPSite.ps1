Function Upload-FileToSPSite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$SPSiteURL,
        [Parameter(Mandatory=$true)][string]$DocumentLibrary,
        [Parameter(Mandatory=$true)][string]$LocalFile
    )

    try{
        Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction Stop

        if(!(Test-Path -Path $LocalFile)){
            Write-Warning -Message "`"$LocalFile`" not found"
        }
        else{
            if($DocumentLibrary -match "^/"){
                #Exception if starting slash: "Server relative urls must start with SPWeb.ServerRelativeUrl"
                Write-Warning -Message "DocumentLibrary should not start with a slash"
            }
            else{
                $FileObj = Get-ChildItem -Path $LocalFile

                $SPWebObj = Get-SPWeb $SPSiteURL -ErrorAction Stop -Verbose:$false
                $List = $SPWebObj.GetFolder($DocumentLibrary)
                $Files = $List.Files

                #region Replace potential ending slash before building full path to SiteAndDocumentPath
                    $SPSiteURL = $SPSiteURL -replace "/$",""
                    $SiteAndDocumentPath = "$SPSiteURL/$DocumentLibrary"
                #endregion

                #Delete the File from library, if it exists!
                if( $Files.Name -contains $FileObj.Name ){
                    $CreatedTimestamp = ($Files | Where {$_.Name -eq $FileObj.Name}).TimeCreated
                    $CreatedTimestamp = $CreatedTimestamp.ToLocalTime()

                    Write-Verbose -Message "Updating $($FileObj.Name) with old timestamp $($CreatedTimestamp.ToString("yyyy-MM-dd HH:mm:ss"))"
                    $Files.Delete("$SiteAndDocumentPath/$($FileObj.Name)")
                }

                #Add File to the collection
                $Files.Add("$($SiteAndDocumentPath)/" + $($FileObj.Name),$FileObj.OpenRead(),$false) | Out-Null
                Write-Verbose -Message "Successfully uploaded $($FileObj.Name)"

                #Dispose the objects
                $SPWebObj.Dispose()
            }
        }
    }
    catch { Write-Warning -Message "Error occurred when trying to upload file. Exception: $($_.Exception.Message)" }
}

#Example
#Upload-FileToSPSite -SPSiteURL "https://internalsharepointserver/sharedproject/worknamehere/" -DocumentLibrary "Shared%20Documents/Folder123" -LocalFile "C:\filetoupload.csv" -Verbose
