## Hashtables is really useful in PowerShell. Once you start using them, you wont stop :)
## A hashtable is a data structure like an array, but hashtables store their values in key/value pairs.

## Lets create a hashtable:
$myFirstHash = @{}

## They are defined almost the same as an array that uses parenthesis e.g. @classicArray = @()
## You can add data to the hashtable like this...

$myFirstHash.Add("Micke","Stockholm")

## or with variables
$key = "Torgny"
$value = "Malmö"
$myFirstHash.Add($key,$value)

## You can also create the hashtable with pre-populated keys and values..
$myFirstHash = @{
  Micke = "Stockholm"
  Torgny = "Malmö"
}

## Or why not a one-liner with semicolons
$myFirstHash = @{ Micke = "Stockholm" ; Torgny = "Malmö" }

## Or why not like this? (Keys will be added if they do not exist, if they exists they are updated)
$myFirstHash = @{}
$myFirstHash.Micke = "Stockholm"
$myFirstHash.Torgny = "Malmö"

## Once data is in there, you probably want to go get the data. Can be done in more than one way.
## Using the Key to get the value back:
$myFirstHash['Torgny']

## Very easy to update Torgnys home town:
$myFirstHash['Torgny'] = "Sollefteå"

### Hashtables are really useful to use to dynamically populate and get data.
## for example inserting all AD-users in a specific OU:
$myADUserHash = @{}
Get-ADUser -filter * -Searchbase "OU=blabla,OU=blabla,DC=bla,DC=bla" | foreach {$myADUserHash.Add($_.SamAccountName,$_)}

## Now you can really easy get my DN by pointing to my key in the hashtable which is my SamAccountName (username).
$myADUserHash.maekee.DistinguishedName

## This works because on the value i placed the AD user object instead of a string value.
### Hashtables crush arrays in speed when you come up to a few hundred or thousand entrys.

### One thing that hashtables cannot easily as arrays is iterating through them.
## The pipeline treats the hashtable as one object ("$myHash | Measure-Object" returns 1)
## What you need to do is iterate through either only the Key or the Value like this:
$myHash.keys | foreach {"do this"}

## If you want both keys and values you need to use the method GetEnumerator(), like this:
$myHash.GetEnumerator() | foreach {"$($_.key) is the Key and $($_.value) is the value"}

## So, we have a hashtable with some key/value pairs
$per @@
#Hashtable inception? You can place hash tables inside an hashtable!
