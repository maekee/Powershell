## Updated 31/10 2019
#Just found out that Microsoft no longer recommends using ArrayLists for new development in dotnet, they instead
#recommend using the type-specific List<T> class.
#So i will add some examples below. See link below for more info
#https://github.com/dotnet/platform-compat/blob/master/docs/DE0006.md

#One of the most common ways of creating arrays today is the $array += "newvalue"
#My take on this is, if its not just a few small values, stop using it now.
#There are better alternatives.

#Arrays are fixed sized in dot net, powershell does a work-around with this by basically
#re-creating a new array for every new item added with += and throwing away the old array.
#This is far from optimal when talking performance. Hash tables and the list class manages this in a much better way
#by using methods used for the purpuse. You define a string collections list like this:

#Using hash tables or other better classes in the collections namespace, you can use better looking
#code and will get a major performance improvement instead of throwing away and rebuilding arrays.

#Lets define a collections List of data type strings:
$stringList = New-Object System.Collections.Generic.List[string]

#or like this:
$stringList = [System.Collections.Generic.List[string]]::new()

#Now add a string value, like this:
$stringList.Add("stringOne")

#You can as easily define integer list or list of Microsoft.ActiveDirectory.Management.ADUser.
$intList = New-Object System.Collections.Generic.List[int]
$adUserList = New-Object System.Collections.Generic.List[Microsoft.ActiveDirectory.Management.ADUser]

#You can have a list of any data type, but when you don’t know the type of objects,
#why not use the [List[PSObject]] to contain them:
$psObjList = [List[PSObject]]::New()

#Microsoft no longer recommends using Arraylits, for different reasons. See links below for more info:
#See remarks: https://docs.microsoft.com/en-us/dotnet/api/system.collections.arraylist?view=netframework-4.8
#Arraylists works similar but is typeless and can be defined like this:
$arraylist = New-Object System.Collections.ArrayList

#You add new items to the arraylist just like a hashtable with the Add method but only provide one value instead of the
#key-pair values. Like this:
$arraylist.Add($NewMemberVariable)

#If you want to remove the host output use void:
[void]$arraylist.Add($NewMemberVariable)
#void is faster than by piping to Out-Null, because then you dont have to pipe the objects to throw them away.

#Here is some statistics on using arrays, arraylists, hashtables and a list.

$array = @()
$hashtable = @{}
$arraylist = New-Object System.Collections.ArrayList
$stringList = New-Object System.Collections.Generic.List[string]
$intList = New-Object System.Collections.Generic.List[int]
$adUserList = New-Object System.Collections.Generic.List[Microsoft.ActiveDirectory.Management.ADUser]

Measure-Command {1..100000 | Foreach { $array += $_} }
#Days              : 0
#Hours             : 0
#Minutes           : 10
#Seconds           : 26
#Milliseconds      : 863
#Ticks             : 6268636481
#TotalDays         : 0,0072553662974537
#TotalHours        : 0,174128791138889
#TotalMinutes      : 10,4477274683333
#TotalSeconds      : 626,8636481
#TotalMilliseconds : 626863,6481 

Measure-Command {1..100000 | Foreach { $hashtable.Add($_,$_) } }
#Days              : 0
#Hours             : 0
#Minutes           : 0
#Seconds           : 1
#Milliseconds      : 661
#Ticks             : 16618881
#TotalDays         : 1,92348159722222E-05
#TotalHours        : 0,000461635583333333
#TotalMinutes      : 0,027698135
#TotalSeconds      : 1,6618881
#TotalMilliseconds : 1661,8881 

Measure-Command {1..100000 | Foreach { $arraylist.Add($_) } }
#Days              : 0
#Hours             : 0
#Minutes           : 0
#Seconds           : 1
#Milliseconds      : 601
#Ticks             : 16018526
#TotalDays         : 1,85399606481481E-05
#TotalHours        : 0,000444959055555556
#TotalMinutes      : 0,0266975433333333
#TotalSeconds      : 1,6018526
#TotalMilliseconds : 1601,8526

Measure-Command {1..100000 | Foreach { $stringList.Add($_) } }
#Days              : 0
#Hours             : 0
#Minutes           : 0
#Seconds           : 1
#Milliseconds      : 762
#Ticks             : 17629714
#TotalDays         : 2,04047615740741E-05
#TotalHours        : 0,000489714277777778
#TotalMinutes      : 0,0293828566666667
#TotalSeconds      : 1,7629714
#TotalMilliseconds : 1762,9714

Measure-Command {1..100000 | Foreach { $intList.Add($_) } }
#Days              : 0
#Hours             : 0
#Minutes           : 0
#Seconds           : 1
#Milliseconds      : 556
#Ticks             : 15569477
#TotalDays         : 1,80202280092593E-05
#TotalHours        : 0,000432485472222222
#TotalMinutes      : 0,0259491283333333
#TotalSeconds      : 1,5569477
#TotalMilliseconds : 1556,9477

Measure-Command {
    $adUserObj = Get-ADUser <username>
    1..100000 | Foreach { $adUserList.Add($adUserObj) } 
}
#Days              : 0
#Hours             : 0
#Minutes           : 0
#Seconds           : 1
#Milliseconds      : 506
#Ticks             : 15066423
#TotalDays         : 1,74379895833333E-05
#TotalHours        : 0,00041851175
#TotalMinutes      : 0,025110705
#TotalSeconds      : 1,5066423
#TotalMilliseconds : 1506,6423

#So.. as you see. 10 minutes vs ~1,6 seconds.
#As you see i only added numbers in the Array, what if that was instead ADUsers or some other object with alot of properties??
#I rest my case

#strongly recommend this link for further reading:
#https://powershellexplained.com/2018-10-15-Powershell-arrays-Everything-you-wanted-to-know/#generic-list
