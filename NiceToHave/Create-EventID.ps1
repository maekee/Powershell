## Simple Function to Create EventID 1337 in the Application EventLog
## Add your own parameters to customize Computername, EventSource, EventID, Severity or EventLog

Function Create-EventID{
	$EventLog = New-Object System.Diagnostics.EventLog('Application')
	$EventLog.MachineName = "."
	$EventLog.Source = "InputCustomSourceHere"
	$EventID = 1337
	$EventLog.WriteEntry("Something went wrong trying something","Warning", $EventID)
}
