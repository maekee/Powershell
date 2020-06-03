#Seems like calling powershell.exe with the parameter -ExecutionPolicy AllSigned gets ignored if the system have Unrestricted.
#Solved this like this:

powershell.exe -NoLogo -NoProfile -Command "& {Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope Process -Force;try{c:\script.ps1 }catch{'<SkapaEventID>'}}"

#This like sets the Execution policy to AllSigned for the current process session, then calls the script and if it
#failes it will execute whatever code you need, i am planning to create an eventID with the exeception message.
#My plan is to use Task Scheduler to execute this command, because the script is located locally i dont want
#anyone to modify the content and elevate their own permissions. If they modify the script, it doesnt run.
#And they cannot change the Task Sequence command without having to enter the service account password again
