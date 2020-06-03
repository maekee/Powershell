#This script takes a textfile that have space separated values with first row beeing column names
#If needed, just replace the split on the space for what ever you want.
#Examples of this can be output from commands, Firewall logs etc.
#Column names, number of columns, values and number of rows can be changed.
#The black regex magic is to support column names and values with spaces if double quotation marks is used (i.e "").

#Update: Have noticed that if files are very big (100k lines) the split on the regex slows the script down,
#so if a space (' ') is enough on the split, use that.

#Example:
#column1 column2 column3
#value001 value002 value003
#data001 data002 data003
#here there everywhere

$FileContent = Get-Content C:\LogFiles\FWLogfile.txt -Encoding UTF8
$PropertyNames = $FileContent[0] -split  ' +(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)'
$Array = New-Object System.Collections.ArrayList

#Create PSObjects and add to Arraylist $Array
foreach ($FileRow in ($FileContent | Select -Skip 1) ){
    $FileRowSplit = $FileRow -split  ' +(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)'
    $propHash = [Ordered]@{}

    for ($i = 0; $i -lt $PropertyNames.Count; $i++){ 
        $propHash.$($PropertyNames[$i]) = $FileRowSplit[$i]
    }

    $NewObject = New-Object PSObject -Property $propHash
    $Array.Add($NewObject) | Out-Null
}
