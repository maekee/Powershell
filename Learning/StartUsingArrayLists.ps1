#One of the most common ways of creating arrays today are the $array += "newvalue"
#My take on this is, if its not just a few small values, stop using it now.
#I present to you.. the Arraylist.

#With the Arraylist you can use better looking code and will get a major performance improvements.
#Because Arrays are fixed sized from .NET powershell does a work around with this by basically
#creating a new array for every += and throwing away the old array. This is not so nice when talking
#performance. Arraylists are a much easier way and very easy to do.
#You define a arraylist like this:
$arraylist = New-Object System.Collections.ArrayList

#Now you can add new items to the arraylist just like a hashtable with the Add method. Like this:
$arraylist.Add($NewMemberVariable)
#If you want to remove the output use void:
[void]$arraylist.Add($NewMemberVariable)
#void is faster than by piping to Out-Null, because then you dont have to pipe to throw away.

#Here is some statistics on using arrays, arraylists and hashtables.
#I added hashtables so you can see the difference there to, but hashtables handles with key-value pairs unlike arrays and arraylists.

$array = @()
$hashtable = @{}
$arraylist = New-Object System.Collections.ArrayList

Measure-Command {1..100000 | Foreach { $array += $_} }
#Days              : 0
#Hours             : 0
#Minutes           : 7
#Seconds           : 3
#Milliseconds      : 857
#Ticks             : 4238574017
#TotalDays         : 0,00490575696412037
#TotalHours        : 0,117738167138889
#TotalMinutes      : 7,06429002833333
#TotalSeconds      : 423,8574017
#TotalMilliseconds : 423857,4017 

Measure-Command {1..100000 | Foreach { $hashtable.Add($_,$_) } }
#Days              : 0
#Hours             : 0
#Minutes           : 0
#Seconds           : 0
#Milliseconds      : 730
#Ticks             : 7302725
#TotalDays         : 8,45222800925926E-06
#TotalHours        : 0,000202853472222222
#TotalMinutes      : 0,0121712083333333
#TotalSeconds      : 0,7302725
#TotalMilliseconds : 730,2725 

Measure-Command {1..100000 | Foreach { $arraylist.Add($_) } }
#Days              : 0
#Hours             : 0
#Minutes           : 0
#Seconds           : 0
#Milliseconds      : 708
#Ticks             : 7087966
#TotalDays         : 8,20366435185185E-06
#TotalHours        : 0,000196887944444444
#TotalMinutes      : 0,0118132766666667
#TotalSeconds      : 0,7087966
#TotalMilliseconds : 708,7966 

#So.. as you see. 7 minutes vs 700 milliseconds.
#As you see i only add numbers, what if that was ADUsers or som other object with alot of properties??
#I rest my case
