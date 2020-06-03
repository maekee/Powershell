#Lets say you have this date object:
$dateObj = Get-Date

#If you need to reformat before sending it to a log or something, you can reformat it with:
$dateObj.ToString('yyyy-MM-dd HH:mm:ss')
