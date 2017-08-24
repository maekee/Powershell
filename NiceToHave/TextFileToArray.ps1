#This script takes a textfile that have space separated values with first row beeing column names
#If needed, just replace the split on the space for what ever you want.
#Examples of this can be output from commands, Firewall logs etc.
#Column names, number of columns, values and number of rows can be changed.

#Example:
#column1 column2 column3
#value001 value002 value003
#data001 data002 data003
#here there everywhere

$FileContent = Get-Content C:\LogFiles\FWLogfile.txt -Encoding UTF8
$PropertyNames = $FileContent[0] -split ' '
$Array = New-Object System.Collections.ArrayList

#Create PSObjects and add to Arraylist $Array
foreach ($FileRow in ($FileContent | Select -Skip 1) ){
    $FileRowSplit = $FileRow -split ' '
    $propHash = [Ordered]@{}

    for ($i = 0; $i -lt $PropertyNames.Count; $i++){ 
        $propHash.$($PropertyNames[$i]) = $FileRowSplit[$i]
    }

    $NewObject = New-Object PSObject -Property $propHash
    $Array.Add($NewObject) | Out-Null
}