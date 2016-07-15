Function Test-MultiParamSets {
    Param(
        [Parameter(ParameterSetName='File')]
        [String]$FilePath,
        [Parameter(ParameterSetName='File')]
        [Switch]$ShowExtension,
 
        [Parameter(ParameterSetName='Folder')]
        [String]$FolderPath,
        [Parameter(ParameterSetName='Folder')]
        [Switch]$FolderSizeInMB
    )

    IF($PSCmdlet.ParameterSetName -eq 'File'){
        IF($ShowExtension){ Get-Item $FilePath | Select FullName,Extension }
        ELSE{ Get-Item $FilePath | Select FullName }
    }
    ELSEIF($PSCmdlet.ParameterSetName -eq 'Folder'){
        IF($FolderSizeInMB){ Get-Item $FolderPath | Select FullName,@{N="SizeMB";E={ "{0:N2}" -f $((Get-ChildItem $FolderPath -Recurse | Measure-Object -property length -sum).Sum/1MB) + " MB" } }}
        ELSE{ Get-Item $FolderPath | Select FullName }
    }
}
