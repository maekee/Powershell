## This file is for your poor techs that still use Service Manager, i was trying to find this script online and saw that the only blog that had it was offline. So i decided to post it here, below is original script from Patrik @ litware.se

#
#Author: Patrik Sundqvist, www.litware.se
#Description: Can be used to archive attached files
#

param([Guid] $Id = $(throw "Parameter `$Id is required. This should be the internal id of a work item or config item which attached files you want to archive."),
[string]$ArchiveRootPath = $(throw "Parameter `$ArchiveRootPath is required. A folder containing all file attachments will be created in this folder."),
[string]$ComputerName = "localhost")

$WIhasAttachMent = "aa8c26dc-3a12-5f88-d9c7-753e5a8a55b4"
$CIhasAttachMent = "095ebf2a-ee83-b956-7176-ab09eded6784"

#Adjust path
$ArchiveRootPath = $ArchiveRootPath.TrimEnd("\")

#Make sure path exists
if(!(Test-Path $ArchiveRootPath))
{
    Write-Error "Provided archive path $ArchiveRootPath doesn't exists" -ErrorAction Stop
}

#Making sure smlets is loaded
if(!(get-module smlets))
{
    import-module smlets -Force -ErrorAction Stop    
}

#Get Emo
$Emo = Get-SCSMObject -Id $Id -ComputerName $ComputerName


#Check if this is a work item or config item
$WIhasAttachMentClass = Get-SCSMRelationshipClass -Id $WIhasAttachMent -ComputerName $ComputerName
$WIClass = Get-SCSMClass System.WorkItem$ -ComputerName $ComputerName
#Figure out if this is a work item or a config item to make sure we use the correct relationship
if($Emo.IsInstanceOf($WIClass))
{
    $files = Get-SCSMRelatedObject -SMObject $Emo -Relationship $WIhasAttachMentClass -ComputerName $ComputerName
}
else
{
    $CIhasAttachMentClass = Get-SCSMRelationshipClass -Id $CIhasAttachMent -ComputerName $ComputerName
    $CIClass = Get-SCSMClass System.ConfigItem$ -ComputerName $ComputerName
    if($Emo.IsInstanceOf($CIClass))
    {
        $files = Get-SCSMRelatedObject -SMObject $Emo -Relationship $CIhasAttachMentClass -ComputerName $ComputerName
    }
    else
    {
        Write-Error "Instance isn't of supported type" -ErrorAction Stop
    }
}

#For each file, archive to entity folder
if($files -ne $Null)
{
    #Create archive folder
    $nArchivePath = $ArchiveRootPath + "\" + $Emo.Id
    New-Item -Path ($nArchivePath) -ItemType "directory" -Force|Out-Null

    $files|%{
            Try
            {
                $_.DisplayName
                $fs = [IO.File]::OpenWrite(($nArchivePath + "\" + $_.DisplayName))
                $memoryStream = New-Object IO.MemoryStream
                $buffer = New-Object byte[] 8192
                [int]$bytesRead|Out-Null
                while (($bytesRead = $_.Content.Read($buffer, 0, $buffer.Length)) -gt 0)
                {
                    $memoryStream.Write($buffer, 0, $bytesRead)
                }        
                $memoryStream.WriteTo($fs)
            }
            Finally
            {
                $fs.Close()
                $memoryStream.Close()
            }
    }
}
