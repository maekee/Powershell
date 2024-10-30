## These functions work with API keys
## if multiple vDOMs are not present, remove the '?vdom=data' in the $APIData object in every function. Otherwise update the "data" value
## Have used them all so they are fully function, customize them for your 
## Enjoy!

Function Convert-CIDRToSubnetMask {
    [CmdletBinding()]
    param ([Parameter(Mandatory=$true)][int]$cidr)

    # Create a binary string with the number of 1s equal to the CIDR value
    $binaryMask = ("1" * $cidr).PadRight(32, "0")

    # Split the binary string into 8-bit segments and convert each to a decimal number
    $subnetMask = (($binaryMask -split "(.{8})" | Where-Object { $_ -ne "" }) | Foreach {
        [convert]::ToInt32($_, 2)
    }) -join "."

    $subnetMask
}
Function Get-FortiGateAddressObject{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]$AddressName,
        [Parameter(Mandatory=$false)][ValidateSet('Subnet','IPRange','FQDN','Geography','Dynamic')][string]$AddressType,
        [Parameter(Mandatory=$true)]$FortiGateUrl,
        [Parameter(Mandatory=$true)]$APIKey,
        [Parameter(Mandatory=$false)][switch]$RawTopObjectOnly
    )

    $APIData = @{
        Address = "$FortiGateUrl"
        API = @{
            Attributes = @{ Headers = @{ Authorization = "Bearer $APIKey";'Content-Type' = 'application/json' } }
            EndpointFWAddress = 'api/v2/cmdb/firewall/address?vdom=data'
        }
    }

    $AddressTypeHash = @{
        "Subnet" = "ipmask"
        "IPRange" = "iprange"
        "FQDN" = "fqdn"
        "Geography" = "geography"
        "Dynamic" = "dynamic"
    }

    $RestAttributes = $APIData.API.Attributes
        
    # Get all address objects
    try{
        $addressResults = Invoke-RestMethod -Method Get -Uri "$($APIData.Address)/$($APIData.API.EndpointFWAddress)" @RestAttributes -ErrorAction Stop -WarningAction Stop
    }
    catch{}

    if($addressResults){
        # Declare variable to filter, this is because its possible to return original object with $RawTopObjectOnly
        $addressResultsList = $addressResults.results

        if($AddressName){ $addressResultsList = $addressResults.results | Where {$_.name -eq $AddressName} }

        if($AddressType){ $addressResultsList = $addressResults.results | Where {$_.type -eq $($AddressTypeHash.$($AddressType))} }
    }

    # return results from API reqeust
    if($RawTopObjectOnly){
        @($addressResults)
    }
    else{
        @($addressResultsList)
    }
}
Function Get-FortiGateGroupObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$FortiGateUrl,
        [Parameter(Mandatory=$false)]$GroupName,
        [Parameter(Mandatory=$true)]$APIKey,
        [Parameter(Mandatory=$false)][switch]$RawTopObjectOnly
    )

    $APIData = @{
        Address = "$FortiGateUrl"
        API = @{
            Attributes = @{ Headers = @{ Authorization = "Bearer $APIKey";'Content-Type' = 'application/json' } }
            EndpointFWAddress = 'api/v2/cmdb/firewall/addrgrp?vdom=data'
        }
    }

    $RestAttributes = $APIData.API.Attributes
    $addressResults = Invoke-RestMethod -Method Get -Uri "$($APIData.Address)/$($APIData.API.EndpointFWAddress)" @RestAttributes -ErrorAction Stop -WarningAction Stop

    if($addressResults.results){
        #Filter if GroupName parameter is used
        if($GroupName){ $outputResults = @($addressResults.results | Where {$_.name -eq $GroupName}) }
        else{ $outputResults = $addressResults.results }
    }

    # return results from API reqeust
    if($RawTopObjectOnly){
        @($addressResults)
    }
    else{
        @($outputResults)
    }
}
Function Add-FortiGateAddressObject{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$FortiGateUrl,
        [Parameter(Mandatory=$true)][string]$APIKey, #Needs Write permission
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$AddressValue,
        [Parameter(Mandatory=$true)][ValidateSet('Subnet','FQDN')]$AddressType,
        [Parameter(Mandatory=$false)][string]$Comment
    )

    $APIData = @{
        Address = "$FortiGateUrl"
        API = @{
            Attributes = @{ Headers = @{ Authorization = "Bearer $APIKey";'Content-Type' = 'application/json' } }
            EndpointFWAddress = 'api/v2/cmdb/firewall/address?vdom=data'
        }
    }

    #region Define address object properties, that goes into the POST Body
        $AddressObjectProperties = @{
            "name" = $Name
        }

        if($AddressType -eq "FQDN"){
            [void]$AddressObjectProperties.Add("type","fqdn")
            [void]$AddressObjectProperties.Add("fqdn",$AddressValue)
        }
        if($AddressType -eq "Subnet"){
            [void]$AddressObjectProperties.Add("type","subnet")
            [void]$AddressObjectProperties.Add("subnet",$AddressValue)
        }

        # Add Comment if present
        if($Comment){ [void]$AddressObjectProperties.Add("comment",$Comment) }
    #endregion

    #region Validation before request
        if($AddressType -eq "Subnet" -and $AddressValue -notmatch '\d+\.\d+\.\d+.\d+\s\d+\.\d+\.\d+.\d+'){
            Write-Warning -Message "Incorrect Subnet format, expected `"IP SUBNET`" (like 192.168.100.1 255.255.255.255)"
            $ValuesOK = $true
        }
        else{
            $ValuesOK = $false
        }
    #endregion

    $AddressObjectPropertiesInJson = $AddressObjectProperties | ConvertTo-Json
    $RestAttributes = $APIData.API.Attributes
    
    $requestResult = Invoke-RestMethod -Method Post -Uri "$($APIData.Address)/$($APIData.API.EndpointFWAddress)" @RestAttributes -ErrorAction Stop -WarningAction Stop -Body $AddressObjectPropertiesInJson
    if($requestResult.status -eq "success" -and $requestResult.http_status -eq "200"){
        $requestResult
       
        Write-Verbose -Message "Successfully added `"$($requestResult.mkey)`" with value `"$($AddressObjectProperties.fqdn)`"" -Verbose
    }
}
Function Add-FortiGateGroupObjectMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$FortiGateUrl,
        [Parameter(Mandatory=$true)]$GroupName,
        [Parameter(Mandatory=$true)]$MemberAddressObject,
        [Parameter(Mandatory=$true)]$APIKey #API key is used both for GET and POST

    )

    $APIData = @{
        Address = "$FortiGateUrl"
        API = @{
            Attributes = @{ Headers = @{ Authorization = "Bearer $APIKey";'Content-Type' = 'application/json' } }
            EndpointFWAddress = "api/v2/cmdb/firewall/addrgrp/$GroupName/?vdom=data"
        }
    }
    $RestAttributes = $APIData.API.Attributes

    #region Get address object and group object
        # Get address object (new member)
        try{
            $fgtaddrmember = Get-FortiGateAddressObject -AddressName $MemberAddressObject -FortiGateUrl $FortiGateUrl -APIKey $APIKey
        }
        catch{
            Write-Error -Message "Error getting FortiGate address object `"$MemberAddressObject`" from `"$FortiGateUrl`". Exception $($_.Exception.Message)" -Exception ([System.Net.WebException]::new())
            break
        }

        # Get target FortiGate group $GroupName
        try{
            $fgtgrpresult = Get-FortiGateGroupObject -FortiGateUrl $FortiGateUrl -GroupName $GroupName -APIKey $APIKey -ErrorAction Stop -WarningAction Stop
        }
        catch{
            Write-Error -Message "Error getting FortiGate group object `"$GroupName`" from `"$FortiGateUrl`". Exception $($_.Exception.Message)" -Exception ([System.Net.WebException]::new())
            break
        }
    #endregion

    # Add group member if group and member found
    if($null -ne $fgtaddrmember -and $null -ne $fgtgrpresult){
    
        # Declare $currentMembers to append new member
        if($fgtgrpresult.member.count -gt 0){
            Write-Verbose -Message "Added $($fgtgrpresult.member.name -join ",") to existing members"
            $currentMembers = $fgtgrpresult.member
        }
        else {
            Write-Verbose -Message "No existing members, new list declared"
            $currentMembers = @()
        }

        #Validate that member is not already present
        
        if($fgtgrpresult.member.name -notcontains $MemberAddressObject){

            # Add the new member to the existing members, or fresh member array
            #Write-Verbose -Message "Add $MemberAddressObject to memberlist" -Verbose
            $currentMembers += @{ "name" = $MemberAddressObject }

            # Define addressGroupUpdate object with group name and currentMembers
            $addressGroupUpdate = @{
                "name" = $GroupName
                "member" = $currentMembers
            }

            $addressGroupUpdateJson = $addressGroupUpdate | ConvertTo-Json -Compress

            <#
                Example of working json output
                {"name":"g-M365Urls","member":[{"name":"AML5447","q_origin_key":"AML5447"},{"name":"AMD010007"}]}
            #>

            #Write-Verbose -Message "Uri : $($APIData.Address)/$($APIData.API.EndpointFWAddress)" -Verbose
            #Write-Verbose -Message $addressGroupUpdateJson -Verbose

            try{
                $PutrequestResult = Invoke-RestMethod -Method Put -Uri "$($APIData.Address)/$($APIData.API.EndpointFWAddress)" @RestAttributes -Body $addressGroupUpdateJson -ErrorAction Stop -WarningAction Stop
            
            }
            catch{
                Write-Error -Message "Error updating FortiGate group address object `"$GroupName`" with member `"$MemberAddressObject`". Exception $($_.Exception.Message)" -Exception ([System.Net.WebException]::new())
                break
            }


            if($PutrequestResult.status -eq "success" -and $PutrequestResult.http_status -eq "200"){
                $PutrequestResult
       
                Write-Verbose -Message "Successfully added `"$MemberAddressObject`" to group `"$GroupName`"" -Verbose
            }
        }
        else{
            Write-Verbose -Message "Address object `"$MemberAddressObject`" already member of `"$GroupName`"" -Verbose
        }

    }
    else{
        # Objects missing
        if($fgtaddrmember -eq $null){ Write-Warning -Message "FortiGate address object `"$($MemberAddressObject)`" not found in `"$FortiGateUrl`"" }
        if($fgtgrpresult -eq $null){ Write-Warning -Message "FortiGate group object `"$($GroupName)`" not found in `"$FortiGateUrl`"" }
    }
}
