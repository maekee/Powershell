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

#The addition operator is also supported:
$myFirstHash += @{Micke = "Stockholm”}

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
## Hashtables crush arrays in speed when you come up to a few hundred or thousand entrys.

### One thing that hashtables cannot easily as arrays is iterating through them.
## The pipeline treats the hashtable as one object ("$myHash | Measure-Object" returns 1)
## What you need to do is iterate through either only the Key or the Value like this:
$myHash.keys | foreach {"do this"}

## If you want both keys and values you need to use the method GetEnumerator(), like this:
$myHash.GetEnumerator() | foreach {"$($_.key) is the Key and $($_.value) is the value"}

### So, we have a hashtable with some key/value pairs
$personHash = @{}
$personHash.Name = ”Micke”
$personHash.Age = 36
$personHash.Location = ”Sweden”

## Now you can navigate around the values with (like an object):
$personHash.Name or $personHash.Age

## Hashtable inception!? You can place an new hashtables inside an hashtable!
$personHash.Location = @{}
$personHash.Location.Country = ”Sweden
$personHash.Location.City = ”Stockholm”
$personHash.Location.AreaCode = ”08”

## or just like this:
@personHash = @{
  Name = ”Micke”
  Age = 36
  Location = @{
    Country = ”Sweden”
    City = ”Stockholm”
    AreaCode = ”08”
  }
}

## And then navigate around like this to the values:
$personHash.Location.City

## Why not like this:
$peopleHash = @{
  Micke = @{
    Age = 36
    Location = @{
      Country = ”Sweden”
      City = ”Stockholm”
      AreaCode = ”08”
    }
  }
  Torgny = @{
    Age = 54
    Location = @{
      Country = ”Sweden”
      City = ”Malmö”
      AreaCode = ”040”
    }
  }
}

### You get Torgnys City like this:
$peopleHash.Torgny.City



… Coming up.. splatting and for optional parameters
Easy way to show content in hashtable: @hashTable | ConvertTo-Json

Save to file and read from file:
$hash | ConvertTo-Json | Set-Content -Path $path
$hash = Get-Content -path $path -Raw | ConvertFrom-Json

Import file with powershell syntax… [scriptblock]…

Creating object from hash table: [pscustomobject]$myHash
This will give you column names…