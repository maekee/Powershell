#Every wondered how to use specific exception types in the try-catch?
#When an exception is thrown, you can see what type it is by just adding the line $_.Exception.GetType().FullName to the catch block.
#The example below returns System.Management.Automation.ItemNotFoundException

try { Get-ChildItem c:\missingfolder -ErrorAction Stop }
catch { $_.Exception.GetType().FullName }

#Now if you want to create a capture scriptblock for this exception, just add it like this:

try { Get-ChildItem c:\missingfolder -ErrorAction Stop }
catch [System.Management.Automation.ItemNotFoundException] { Write-Warning "Item Not Found Errors" }
catch { Write-Warning "This time the exception was $($_.Exception.GetType().FullName)" }

#If you want to iterate through all of the currently loaded exceptions in PowerShell, run this code:
[appdomain]::CurrentDomain.GetAssemblies() | ForEach {
        try { $_.GetExportedTypes() | Where { $_.Fullname -match 'Exception' } }
        catch {}
} | Select FullName

#Happy exception hunting
