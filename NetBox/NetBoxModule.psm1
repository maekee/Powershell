$Global:NetBoxSettings = @{
    Test = @{
        Label = "NetBox Test"
        API = 'https://netboxtest.domain.com/api'
    }
    Prod = @{
        Label = "NetBox Prod"
        API = 'https://netboxprod.domain.com/api'
    }
    ResultLimit = 1000
}

Function Get-NetBoxPrefix{
    <#
    .SYNOPSIS
    Gets NetBox prefixes

    .DESCRIPTION
    Get specific prefix or all available in NetBox from RestAPI
 
    .PARAMETER Prefix
    Parameter to specify specific prefix in the format x.x.x.x/y

    .PARAMETER Environment
    Points to either a test NetBox instance or a prod instance. Uses NetBoxSettings variable

    .PARAMETER NetBoxToken
    Used to authenticate/authorize in NetBox.

    .PARAMETER IncludePSObject
    Switch parameter to include the original RestAPI response object.

    .EXAMPLE
    Get-NetBoxPrefix -Environment Test -NetBoxToken "<tokenhere>"
    Returns a list of all available prefixes in NetBox test instance

    Get-NetBoxPrefix -Prefix 192.168.1.0/24 -Environment Test -NetBoxToken "<tokenhere>"
    Returns the prefix 192.168.1.0/24 prefix in NetBox test instance if available

    .NOTES
    Requires that variable $NetBoxSettings is loaded (declared as global in NetBoxModule.psm1)
    The workaround "ugly" GetEncoding-code is to get around the PowerShell bug when it comes to utf8-encoding

    Author:     @mickesunkan
    Github:      https://github.com/maekee/Powershell
    #>
    [CmdLetBinding()]
    param (
        [Parameter(Mandatory=$false)][string]$Prefix,
        [Parameter(Mandatory=$true)][string][ValidateSet('Test','Prod')]$Environment, #Environment mappas i NetBoxSettings
        [Parameter(Mandatory=$true)][string]$NetBoxToken,
        [Parameter(Mandatory=$false)][switch]$IncludePSObject
    )

    #region function variables (environment, prefix, header)
        $DynamicUrl = "{0}/{1}/{2}" -f $NetBoxSettings.$($Environment).API,"ipam","prefixes" #Base Prod IPAM Endpoint
        $EnvLabel = $NetBoxSettings.$($Environment).Label

        #region Add Prefix parent if supplied (and limit)
            if($PSBoundParameters.ContainsKey('Prefix')){
                Write-Verbose -Message "Parameter Prefix used with value `"$Prefix`""
                    
                if($Prefix -notmatch "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}\/\d+$"){
                    Write-Warning -Message "You need to supply the prefix in the format x.x.x.x/y"
                    $DynamicUrl += "?prefix=incorrectprefix" #0 results back because om failed prefix format should not return all prefixes
                }
                else{
                    $DynamicUrl += "?prefix={0}&limit={1}" -f $Prefix,$NetBoxSettings.ResultLimit
                }
            }
            else{
                $DynamicUrl += "?limit={0}" -f $NetBoxSettings.ResultLimit
            }
        #endregion

        $GetDataAttributes = @{
            Headers     = @{ Authorization = "Token $NetBoxToken" }
            ContentType   = 'application/json; charset=utf-8'
        }
    #endregion

    #region NetBox API request
        try{
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $NetBoxResult = Invoke-RESTMethod -Uri $DynamicUrl @GetDataAttributes -Method Get -ErrorAction Stop -Verbose:$false
        }
        catch{
            Write-Warning -Message "Error occurred while getting NetBox data. Exception: $($_.Exception.Message)"
        }
    #endregion

    #region Validating API response
        if($NetBoxResult.count -gt 0){

            $NetBoxColumns = @{Name="Prefix-nosuffix";Expression={$_.prefix -replace "\/\d+",""}},
                @{Name="Prefix-suffix";Expression={$_.prefix}},
                @{Name="Prefix-3";Expression={$_.prefix -replace "\.0/\d+",""}},
                @{Name="Status";Expression={$_.status.label}},
                @{Name="Site";Expression={$_.site.display}}, #Used in Add-NetBoxTag
                @{Name="Role Name";Expression={
                    if($_.role.name){
                        [System.Text.Encoding]::UTF8.GetString( [System.Text.Encoding]::GetEncoding("iso-8859-1").GetBytes($_.role.name) ) -replace "�\\u0085","Å"
                    }
                }},
                @{Name="Description";Expression={
                    if($_.description){
                        [System.Text.Encoding]::UTF8.GetString( [System.Text.Encoding]::GetEncoding("iso-8859-1").GetBytes($_.description) ) -replace "�\\u0085","Å"
                    }
                }},
                @{Name="Url";Expression={$_.url}}, #Used in Add-NetBoxTag
                @{Name="PrefixID";Expression={$_.id}}

            if($IncludePSObject){
                $NetBoxColumns += @{Name="PSObj";Expression={$_}}
            }

            $NetBoxResult.results | Select $NetBoxColumns
        }
        else{
            Write-Verbose -Message "No prefix data found in $EnvLabel" -Verbose
        }
    #endregion
}
Function Get-NetBoxTag{
    <#
    .SYNOPSIS
    Gets NetBox Tags

    .DESCRIPTION
    Get specific tags or all available in NetBox from RestAPI
 
    .PARAMETER Tag
    Parameter to specify specific tag

    .PARAMETER Environment
    Points to either a test NetBox instance or a prod instance. Uses NetBoxSettings variable

    .PARAMETER NetBoxToken
    Used to authenticate/authorize in NetBox.

    .PARAMETER IncludePSObject
    Switch parameter to include the original RestAPI response object.

    .EXAMPLE
    Get-NetBoxTag -Environment Test -NetBoxToken "<tokenhere>"
    Returns a list of all available tags in NetBox test instance

    Get-NetBoxTag -Tag Gateway -Environment Test -NetBoxToken "<tokenhere>"
    Returns the tag "Gateway" in NetBox test instance if available

    .NOTES
    Requires that variable $NetBoxSettings is loaded (declared as global in NetBoxModule.psm1)

    Author:     @mickesunkan
    Github:      https://github.com/maekee/Powershell
    #>
    param (
        [Parameter(Mandatory=$false)][string]$Tag,
        [Parameter(Mandatory=$true)][string][ValidateSet('Test','Prod')]$Environment, #Environment mappas i NetBoxSettings
        [Parameter(Mandatory=$true)][string]$NetBoxToken,
        [Parameter(Mandatory=$false)][switch]$IncludePSObject
    )

    #region function variables (environment, tag, header)
        $DynamicUrl = "{0}/{1}/{2}" -f $NetBoxSettings.$($Environment).API,"extras","tags" #Base Prod IPAM Endpoint
        $EnvLabel = $NetBoxSettings.$($Environment).Label

        if($PSBoundParameters.ContainsKey('Tag')){
            Write-Verbose -Message "Parameter Tag used with value `"$Tag`""
            $DynamicUrl += "?name__ie={0}&limit={1}" -f $Tag,$NetBoxSettings.ResultLimit
        }
        else{
            $DynamicUrl += "?limit={0}" -f $NetBoxSettings.ResultLimit
        }

        $GetDataAttributes = @{
            Headers     = @{ Authorization = "Token $NetBoxToken" }
            ContentType   = 'application/json; charset=utf-8'
        }
    #endregion

    #region NetBox API request
        try{
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $NetBoxResult = Invoke-RESTMethod -Uri $DynamicUrl @GetDataAttributes -Method Get -ErrorAction Stop -Verbose:$false
        }
        catch{
            Write-Warning -Message "Error occurred while getting NetBox data. Exception: $($_.Exception.Message)"
        }
    #endregion

    #region Validating API response
        if($NetBoxResult.count -gt 0){

            $NetBoxColumns = @{Name="Name";Expression={$_.name}},
                @{Name="Slug";Expression={$_.slug}},
                @{Name="Color";Expression={$_.color}},
                @{Name="Description";Expression={$_.description}},
                @{Name="TagID";Expression={$_.id}}

            if($IncludePSObject){
                $NetBoxColumns += @{Name="PSObj";Expression={$_}}
            }

            $NetBoxResult.results | Select $NetBoxColumns
        }
        else{
            Write-Verbose -Message "No tag data found in $EnvLabel" -Verbose
        }
    #endregion
}
Function Get-NetBoxIPaddress{
    <#
    .SYNOPSIS
    Gets NetBox IP address object(s) based on IPAddress or DNS_Name

    .DESCRIPTION
    Get specific NetBox IP address object(s) in NetBox from RestAPI.
 
    .PARAMETER Identity
    Parameter to specify specific either IP address (x.x.x.x/y) or DNSName.
    If value matches x.x.x.x or x.x.x.x/y Value will use IPAddress, otherwise DNSName

    .PARAMETER Environment
    Points to either a test NetBox instance or a prod instance. Uses NetBoxSettings variable

    .PARAMETER NetBoxToken
    Used to authenticate/authorize in NetBox.

    .PARAMETER IncludePSObject
    Switch parameter to include the original RestAPI response object.

    .EXAMPLE
    Get-NetBoxIPaddress -Identity 192.168.1.100/24 -Environment Test -NetBoxToken "<tokenhere>"
    Returns the IP address object

    Get-NetBoxIPaddress -Identity server01 -Environment Test -NetBoxToken "<tokenhere>" -IncludePSObject
    Returns the IP address object by DNS name and include the original RestAPI-response object

    .NOTES
    Requires that variable $NetBoxSettings is loaded (declared as global in NetBoxModule.psm1)
    The workaround "ugly" GetEncoding-code is to get around the PowerShell bug when it comes to utf8-encoding

    Author:     @mickesunkan
    Github:      https://github.com/maekee/Powershell
    #>
    [CmdLetBinding()]
    param (
        [Parameter(Position=0,Mandatory=$true)][string]$Identity,
        [Parameter(Mandatory=$true)][string][ValidateSet('Test','Prod')]$Environment, #Environment mappas i NetBoxSettings
        [Parameter(Mandatory=$true)][string]$NetBoxToken,
        [Parameter(Mandatory=$false)][switch]$IncludePSObject,
        [Parameter(Mandatory=$false)][string][ValidateSet('IPAddress','DNSName')]$Value
    )

    #region AutoIdentity IPAddress/DNSName if not overridden with parameter Value
        if(!($PSBoundParameters.ContainsKey('Value'))){
                if($Identity -match "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}\/\d+$" -or $Identity -match "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$"){ $Value = "IPAddress" }
                else{ $Value = "DNSName" }
        }
    #endregion

    #region function variables (environment, ip-address, header)
        $DynamicUrl = "{0}/{1}/{2}" -f $NetBoxSettings.$($Environment).API,"ipam","ip-addresses" #Base Prod IPAM Endpoint
        $EnvLabel = $NetBoxSettings.$($Environment).Label

        #region Build NetBox API query
            if($Value -eq "IPAddress"){
                Write-Verbose -Message "Searching NetBox for IP Address: $Identity"

                if($Identity -match "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}\/\d+$"){
                    $DynamicUrl += "?address={0}&limit=5" -f $Identity #should be limit=1, but to be sure
                }
                else{
                    Write-Warning -Message "You need to supply the IP Address in the format x.x.x.x/y"
                    $DynamicUrl += "?address=incorrectaddress" #0 results back because of failed address format should not return anything
                }
            }
            elseif($Value -eq "DNSName"){
                Write-Verbose -Message "Searching NetBox for DNS Name: $Identity"

                if($Identity.Length -gt 2){
                    $DynamicUrl += "?dns_name__ie={0}&limit={1}" -f $Identity,$NetBoxSettings.ResultLimit
                }
                else{
                    Write-Warning -Message "DNS Name `"$($Identity)`"? Please supply at least three characters"
                    $DynamicUrl += "?dns_name__ie=incorrectname&limit=1" -f 1
                }
            }
        #endregion

        $GetDataAttributes = @{
            Headers     = @{ Authorization = "Token $NetBoxToken" }
            ContentType   = 'application/json; charset=utf-8'
        }
    #endregion

    #region NetBox API request
        try{
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $NetBoxResult = Invoke-RESTMethod -Uri $DynamicUrl @GetDataAttributes -Method Get -ErrorAction Stop -Verbose:$false
        }
        catch{
            Write-Warning -Message "Error occurred while getting NetBox data. Exception: $($_.Exception.Message)"
        }
    #endregion

    #region Validating API response
        if($NetBoxResult.count -gt 0){
            if($NetBoxResult.count -gt 1){ Write-Verbose -Message "Found $($NetBoxResult.count) entries in $EnvLabel" }

            $NetBoxColumns = @{Name="DNS_name";Expression={$_.dns_name}},
                @{Name="Address";Expression={$_.address}},
                @{Name="Address-nosuffix";Expression={$_.address -replace "\/\d+",""}},
                @{Name="Status";Expression={
                    if($_.status.label){
                        [System.Text.Encoding]::UTF8.GetString( [System.Text.Encoding]::GetEncoding("iso-8859-1").GetBytes($_.status.label) ) -replace "�\\u0085","Å"
                    }
                }},
                @{Name="Description";Expression={
                    if($_.description){
                        [System.Text.Encoding]::UTF8.GetString( [System.Text.Encoding]::GetEncoding("iso-8859-1").GetBytes($_.description) ) -replace "�\\u0085","Å"
                    }
                }},
                @{Name="Tags";Expression={
                    if(@($_.tags).Count -gt 0){
                        $_.tags | Select id,name | Foreach { @{$_.name = $_.id} }
                    }
                    else{@()}
                }},
                @{Name="Environment";Expression={$Environment}}, #This is used to automatically populate Environment when using Pipeline
                @{Name="Url";Expression={$_.url}}, #Used in Add-NetBoxTag
                @{Name="IPAddressID";Expression={$_.id}}

            if($IncludePSObject){
                $NetBoxColumns += @{Name="PSObj";Expression={$_}}
            }

            $NetBoxResult.results | Select $NetBoxColumns
        }
        else{
            Write-Verbose -Message "$Value $Identity not found (no reservation) in $EnvLabel"
        }
    #endregion
}

Function Search-NetBoxIPAddress{
    <#
    .SYNOPSIS
    Enables easy searching of ip address object(s) in NetBox

    .DESCRIPTION
    Searches in NetBox by DNS_Name, Address, Description or parent Prefix.
 
    .PARAMETER Value
    Defines what value to search for on the Field attribute, together with the operator parameter
    If value matches x.x.x.x or x.x.x.x/y Value will use IPAddress, otherwise DNSName. Should Description or Parent
    field be used, explicit use the Field Parameter.

    .PARAMETER Field
    Points to the field that the value will be searched in.

    .PARAMETER Environment
    Points to either a test NetBox instance or a prod instance. Uses NetBoxSettings variable

    .PARAMETER NetBoxToken
    Used to authenticate/authorize in NetBox.

    .PARAMETER IncludePSObject
    Switch parameter to include the original RestAPI response object.

    .PARAMETER Operator
    Sets the operator to use, default operator is Contains.

    .EXAMPLE
    Search-NetBoxIPAddress -Value server -Field DNS_Name -Environment Test -NetBoxToken "<tokenhere>"
    Returns the IP address objects where DNS_Name value contains (default operator) "server" in NetBox test

    Search-NetBoxIPAddress -Value backup -Field Description -Environment Test -NetBoxToken "<tokenhere>"
    Returns the IP address objects where the description value contains (default operator) "backup" in NetBox test

    Search-NetBoxIPAddress -Value "backup server 1" -Field Description -Environment Test -NetBoxToken "<tokenhere>" -Operator ExactMatch
    Returns the IP address objects where the description value have an ExactMatch of "backup server 1" in NetBox test

    .NOTES
    Requires that variable $NetBoxSettings is loaded (declared as global in NetBoxModule.psm1)
    The workaround "ugly" GetEncoding-code is to get around the PowerShell bug when it comes to utf8-encoding

    Author:     @mickesunkan
    Github:      https://github.com/maekee/Powershell
    #>
    [CmdLetBinding()]
    param (
        [Parameter(Position=0,Mandatory=$true)][string]$Value,
        [Parameter(Mandatory=$false)][string][ValidateSet('DNS_Name','Address','Description','Parent')]$Field,
        [Parameter(Mandatory=$true)][string][ValidateSet('Test','Prod')]$Environment, #Environment mappas i NetBoxSettings
        [Parameter(Mandatory=$true)][string]$NetBoxToken,
        [Parameter(Mandatory=$false)][switch]$IncludePSObject,
        [Parameter(Mandatory=$false)][string][ValidateSet('ExactMatch','Contains')]$Operator = "Contains"
    )

    #region AutoIdentity Address, if not address use DNSName. Otherwise override with Field parameter
        if(!($PSBoundParameters.ContainsKey('Field'))){
                if($Value -match "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}\/\d+$" -or $Value -match "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$"){ $Field = "Address" }
                else{ $Field = "DNS_Name" }
        }
        #This can then be overridden with the Field-parameter
    #endregion

    #region function variables (environment, ip-address, header)
        $DynamicUrl = "{0}/{1}/{2}" -f $NetBoxSettings.$($Environment).API,"ipam","ip-addresses" #Base Prod IPAM Endpoint
        $EnvLabel = $NetBoxSettings.$($Environment).Label

        #region Abort if Parent (Prefix) is used and wrong prefix format is used
            if($Field -eq "Parent" -and $Value -notmatch "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}\/\d+$"){
                Write-Warning -Message "You need to supply the Parent (prefix) in the format x.x.x.x/y"
                $AbortAPIRequest = $true
            }
        #endregion

        #Changes from user friendly parameter name to NetBox query parameter name

        $OperatorMapping = @{
            "ExactMatch" = "__ie" #ie : Contains (case-insensitive)
            "Contains" = "__ic" #ic : Exact match (case-insensitive)
        }

        $GetDataAttributes = @{
            Headers     = @{ Authorization = "Token $NetBoxToken" }
            ContentType   = 'application/json; charset=utf-8'
        }
    #endregion

    #region Build NetBox API query
        if($Field -match "(^Address$|^Parent$)"){
            $NetBoxOperator = $null #Address and Parent (prefix) do not support Contains/ExactMatch operators, only field=value
        }
        else{
            $NetBoxOperator = $OperatorMapping.$($Operator)
        }

        $DynamicUrl += "?{0}{1}={2}&limit={3}" -f $($Field.ToLower()),$NetBoxOperator,$Value,$NetBoxSettings.ResultLimit
    #endregion

    #region NetBox API request
        try{
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $NetBoxResult = Invoke-RESTMethod -Uri $DynamicUrl @GetDataAttributes -Method Get -ErrorAction Stop -Verbose:$false
        }
        catch{
            Write-Warning -Message "Error occurred while getting NetBox data. Exception: $($_.Exception.Message)"
        }
    #endregion

    #region Validating API response
        if($AbortAPIRequest -ne $true){
            if($NetBoxResult.count -gt 0){
                if($NetBoxResult.count -gt 1){ Write-Verbose -Message "Found $($NetBoxResult.count) entries in $EnvLabel" }

                $NetBoxColumns = @{Name="DNS_name";Expression={$_.dns_name}},
                    @{Name="Address";Expression={$_.address}},
                    @{Name="Address-nosuffix";Expression={$_.address -replace "\/\d+",""}},
                    @{Name="Status";Expression={
                        if($_.status.label){
                            [System.Text.Encoding]::UTF8.GetString( [System.Text.Encoding]::GetEncoding("iso-8859-1").GetBytes($_.status.label) ) -replace "�\\u0085","Å"
                        }
                    }},
                    @{Name="Description";Expression={
                        if($_.description){
                            [System.Text.Encoding]::UTF8.GetString( [System.Text.Encoding]::GetEncoding("iso-8859-1").GetBytes($_.description) ) -replace "�\\u0085","Å"
                        }
                    }},
                    @{Name="Tags";Expression={
                        if(@($_.tags).Count -gt 0){
                            $_.tags | Select id,name | Foreach { @{$_.name = $_.id} }
                        }
                        else{@()}
                    }},
                    @{Name="Environment";Expression={$Environment}}, #This is used to automatically populate Environment when using Pipeline
                    @{Name="Url";Expression={$_.url}}, #Used in Add-NetBoxTag
                    @{Name="IPAddressID";Expression={$_.id}}

                if($IncludePSObject){
                    $NetBoxColumns += @{Name="PSObj";Expression={$_}}
                }

                $NetBoxResult.results | Select $NetBoxColumns
            }
            else{
                Write-Verbose -Message "$Field $Value not found (no reservation) in $EnvLabel"
            }
        }
    #endregion
}

Function Set-NetBoxIPaddress{
    <#
    .SYNOPSIS
    Updates NetBox ip address object(s) with new Status, Description or DNS_Name

    .DESCRIPTION
    Updates NetBox ip address object(s) with new Status, Description or DNS_Name via RestAPI.
    The function can both be used with pipeline from Get-NetBoxIPAddress and as stand alone.

    .PARAMETER IPAddress
    Parameter to specify which IP addresses (x.x.x.x/y) that will be updated, only used when
    running as standalone and not required when using pipeline.

    .PARAMETER Field
    Points to the field that will be updated

    .PARAMETER Value
    Defines what value Field parameter will be updated to

    .PARAMETER Environment
    Points to either a test NetBox instance or a prod instance. Uses NetBoxSettings variable

    .PARAMETER NetBoxToken
    Used to authenticate/authorize in NetBox.

    .EXAMPLE
    Get-NetBoxIPaddress -Identity 192.168.1.100/24 -Environment Test -NetBoxToken "<tokenhere>" | Set-NetBoxIPaddress -Field Description -Value "New Description" -NetBoxToken "<tokenhere>"
    Updates description for ip address 192.168.1.100/24 object in NetBox test by using the PowerShell pipeline.

    Set-NetBoxIPaddress -IPAddress 192.168.1.100/24 -Field DNS_Name Server01 -Environment Test -NetBoxToken asda
    Updates the DNS_Name field for ip address 192.168.1.100/24 in NetBox test

    .NOTES
    Requires that variable $NetBoxSettings is loaded (declared as global in NetBoxModule.psm1)

    Author:     @mickesunkan
    Github:      https://github.com/maekee/Powershell
    #>
    [CmdLetBinding()]
    param (
        [Parameter(Mandatory=$true,ValueFromPipeline)]$IPAddress,
        [Parameter(Mandatory=$true)][string][ValidateSet('Status','Description','DNS_Name')]$Field, #These should match the RestAPI attribute names, otherwise a mapping hash is required
        [Parameter(Mandatory=$true)][string]$Value,
        [Parameter(Mandatory=$false)][string][ValidateSet('Test','Prod')]$Environment, #Environment is mapped in NetBoxSettings, not required because can come from Get-NetBoxIPAddress (which is also created in Begin-block)
        [Parameter(Mandatory=$true)][string]$NetBoxToken #mandatory because updating NetBox data
    )
    
    Begin{
        #This code block is not executed if PowerShell pipeline is used (Set-NetBoxIPaddress called with IPAddress)
        if($IPAddress){
            if($PSBoundParameters.ContainsKey('Environment')){
                $IPAddress = Get-NetBoxIPaddress -Identity $IPAddress -Environment $Environment -NetBoxToken $NetBoxToken
                if($IPAddress){ $Environment = $IPAddress.Environment }
                else{ $AbortAPIRequest = $true }
            }
            else{
                $AbortAPIRequest = $true
                Write-Warning -Message "Parameter Environment value (Test/Prod) is missing"
            }
        }
    }
    Process{
        #This code block is executed for every pipeline object or object coming from Begin-block
        #region function variables (environment, ip-address, header)
            if($AbortAPIRequest -ne $true){
                #AbortAPIRequest can be set in Begin-block, so this is to avoid exception when checking NetBoxSettings below
                #Built in this code to avoid having to use environment parameter if pipeline is used
                $Environment = $IPAddress.Environment
                $DynamicUrl = "{0}/{1}/{2}" -f $NetBoxSettings.$($Environment).API,"ipam","ip-addresses" #Base Prod IPAM Endpoint
                $EnvLabel = $NetBoxSettings.$($Environment).Label
            }
        #endregion

        if($IPAddress.IPAddressID){
            #region Build Invoke-RESTMethod Parameters including Body with field and field data
                $GetDataAttributes = @{
                    Headers     = @{ Authorization = "Token $NetBoxToken" }
                    ContentType = 'application/json; charset=utf-8'
                }

                #region Validate Status value if used
                    if($Field -eq "Status"){
                        if(!($Value.ToLower().Trim() -match "(^active$|^reserved$|^deprecated$|^dhcp$)")){
                            Write-Warning -Message "`"$($Value.Trim())`" is not approved Status value. Approved values: Active, Reserved, Deprecated, DHCP"
                            $AbortAPIRequest = $true
                        }
                        else{
                            $Value = $Value.ToLower().Trim()
                        }
                    }
                #endregion
                
                [void]$GetDataAttributes.Add("Body","{`"$($Field.ToLower())`": `"$Value`"}")
            #endregion

            #region Validate that new value is different
                if($IPAddress.$($Field) -match "^$Value$"){
                    Write-Verbose -Message "$Field is already set to value `"$Value`" for $($IPAddress.Address) in $EnvLabel, nothing updated" -Verbose
                    $AbortAPIRequest = $true
                }
            #endregion

            #region NetBox API PATCH request
                if($AbortAPIRequest -ne $true){
                    try{
                        $DynamicUrl += "/{0}/" -f $IPAddress.IPAddressID

                        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                        $NetBoxResult = Invoke-RESTMethod -Uri $DynamicUrl @GetDataAttributes -Method Patch -ErrorAction Stop -WarningAction Stop -Verbose:$false

                        Write-Verbose -Message "Successfully updated $Field from `"$($IPAddress.$Field)`" to `"$($NetBoxResult.$Field)`" for $($IPAddress.Address) (id$($IPAddress.IPAddressID)) in $EnvLabel" -Verbose
                    }
                    catch{
                        Write-Warning -Message "Error occurred when trying to update $($Field.ToLower()) from `"$($IPAddress.$Field)`" to `"$($Value)`" for $($IPAddress.Address) (id$($IPAddress.IPAddressID)) in $EnvLabel. Exception: $($_.Exception.Message)"
                    }
                }
            #endregion
        }
    }
    End{}
}
Function Add-NetBoxTag{
    <#
    .SYNOPSIS
    Adds NetBox tags by pipe'ing objects to the function

    .DESCRIPTION
    Adds Netbox Tags to objects by using the PowerShell pipeline and call the RestAPI.
    This function requires using the PowerShell pipeline and cannot be executed as stand alone.
 
    .PARAMETER PipelineObject
    The PowerShell pipeline object is placed on this parameter automatically. Not used manually

    .PARAMETER TagName
    The Name of the existing NetBox Tag that should be added to the pipeline object(s)

    .PARAMETER Environment
    Points to either a test NetBox instance or a prod instance. Uses NetBoxSettings variable

    .PARAMETER NetBoxToken
    Used to authenticate/authorize in NetBox.

    .EXAMPLE
    Get-NetBoxIPaddress -Identity 192.168.1.100/24 -Environment Test -NetBoxToken "<tokenhere>" | Add-NetBoxTag -TagName Backup -Environment Test -NetBoxToken "<tokenhere>"
    Adds the tag Backup for the ip address object 192.168.1.100/24 in NetBox Test

    .NOTES
    Requires that variable $NetBoxSettings is loaded (declared as global in NetBoxModule.psm1)

    Author:     @mickesunkan
    Github:      https://github.com/maekee/Powershell
    #>
    [CmdLetBinding()]
    param (
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline)]$PipelineObject,
        [Parameter(Mandatory=$true)][string]$TagName,
        [Parameter(Mandatory=$true)][string][ValidateSet('Test','Prod')]$Environment, #Mandatory because pipeline objects do not enter Begin-block
        [Parameter(Mandatory=$true)][string]$NetBoxToken #mandatory because updating NetBox data
    )

    Begin{
        #This code block does not contain the Pipeline object, and is only run one time
        if(!($PipelineObject)){
            $TagNameObj = Get-NetBoxTag -Tag $TagName -Environment $Environment -NetBoxToken $NetBoxToken
            
            # If this Tag validation is moved to Process block the Environment parameter do not have to be mandatory,
            # but then the tag is validated once for every pipeline object
            if(!($TagNameObj)){
                Write-Warning -Message "Tag `"$TagName`" not found in NetBox $Environment"
                $AbortAPIRequest = $true
            }
        }
        else{
            Write-Warning -Message "Add-NetBoxTag is only used to pipeline objects to, not stand-alone."
            $AbortAPIRequest = $true
        }
    }
    Process{
        #<#DEBUG Pipeline Objects#> Write-Verbose -Message $PipelineObject -Verbose
        if($null -ne $PipelineObject.Address -and $null -ne $TagNameObj){
            
            if($PipelineObject.Tags.Values -notcontains $TagNameObj.TagID ){
                #region Logging about existing tags if present
                    if($PipelineObject.Tags.Values.Count -eq 0){ Write-Verbose -Message "No existing tags found" }
                    else{ Write-Verbose -Message "Existing tags found: $($PipelineObject.Tags.Keys -join ", ")" }
                #endregion
               
                #region Declare variables
                    $DynamicUrl = "{0}" -f $PipelineObject.Url #Base IPAM Endpoint, not manually built because Tags can be used on multiple object types
                    $EnvLabel = $NetBoxSettings.$($Environment).Label

                    $GetDataAttributes = @{
                        Headers     = @{ Authorization = "Token $NetBoxToken" }
                        ContentType = 'application/json; charset=utf-8'
                    }
                #endregion

                #region Build tag array for RestAPI
                    if($PipelineObject.Tags.Values.Count -eq 0){
                        $TagIDs = $($TagNameObj.TagID)
                    }
                    else{
                        #Build comma separated list with existing tags and new tag
                        $TagIDs = @($PipelineObject.Tags.Values + $TagNameObj.TagID -join ",")
                    }

                    [void]$GetDataAttributes.Add("Body","{`"tags`": [$TagIDs]}")
                #endregion

                #region NetBox API request
                    try{
                        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                        $NetBoxResult = Invoke-RESTMethod -Uri $DynamicUrl @GetDataAttributes -Method Patch -ErrorAction Stop -WarningAction Stop -Verbose:$false

                        Write-Verbose -Message "Successfully added tag `"$($TagNameObj.Name)`" (TagID$($TagNameObj.TagID)) to $($PipelineObject.Address) (id$($PipelineObject.IPAddressID)) in $EnvLabel" -Verbose
                    }
                    catch{
                        Write-Warning -Message "Error occurred when trying to add tag `"$($TagNameObj.Name)`" (TagID$($TagNameObj.TagID)) to $($PipelineObject.Address) (id$($PipelineObject.IPAddressID)) in $EnvLabel. Exception: $($_.Exception.Message)"
                    }
                #endregion
            }
            
            #region Logging if tag is present already
                if($PipelineObject.Tags.Values -contains $TagNameObj.TagID){
                    Write-Verbose -Message "Tag `"$($TagNameObj.Name)`" already set for $($PipelineObject.Address) in NetBox $Environment"
                }
            #endregion
        }
    }
    End{}
}
Function Remove-NetBoxTag{
    <#
    .SYNOPSIS
    Removes NetBox tags by pipe'ing objects to the function

    .DESCRIPTION
    Removes Netbox Tags from objects by using the PowerShell pipeline and call the RestAPI.
    This function requires using the PowerShell pipeline and cannot be executed as stand alone.
 
    .PARAMETER PipelineObject
    The PowerShell pipeline object is placed on this parameter automatically. Not used manually

    .PARAMETER TagName
    The Name of the NetBox Tag that should be removed from NetBox object(s)

    .PARAMETER Environment
    Points to either a test NetBox instance or a prod instance. Uses NetBoxSettings variable

    .PARAMETER NetBoxToken
    Used to authenticate/authorize in NetBox.

    .EXAMPLE
    Get-NetBoxIPaddress -Identity 192.168.1.100/24 -Environment Test -NetBoxToken "<tokenhere>" | Remove-NetBoxTag -TagName Backup -Environment Test -NetBoxToken "<tokenhere>"
    Removes the tag Backup for the ip address object 192.168.1.100/24 in NetBox Test.

    .NOTES
    Requires that variable $NetBoxSettings is loaded (declared as global in NetBoxModule.psm1)

    Author:     @mickesunkan
    Github:      https://github.com/maekee/Powershell
    #>
    [CmdLetBinding()]
    param (
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline)]$PipelineObject,
        [Parameter(Mandatory=$true)][string]$TagName,
        [Parameter(Mandatory=$true)][string][ValidateSet('Test','Prod')]$Environment, #Mandatory because pipeline objects do not enter Begin-block
        [Parameter(Mandatory=$true)][string]$NetBoxToken #mandatory because updating NetBox data
    )

    Begin{
        #This code block does not contain the Pipeline object, and is only run one time
        if(!($PipelineObject)){
            $TagNameObj = Get-NetBoxTag -Tag $TagName -Environment $Environment -NetBoxToken $NetBoxToken
            
            # If this Tag validation is moved to Process block the Environment parameter do not have to be mandatory,
            # but then the tag is validated once for every pipeline object
            if(!($TagNameObj)){
                Write-Warning -Message "Tag `"$TagName`" not found in NetBox $Environment"
                $AbortAPIRequest = $true
            }
        }
        else{
            Write-Warning -Message "Remove-NetBoxTag is only used to pipeline objects to, not stand-alone."
            $AbortAPIRequest = $true
        }
    }
    Process{
        #<#DEBUG Pipeline Objects#> Write-Verbose -Message $PipelineObject -Verbose
        if($null -ne $PipelineObject.Address -and $null -ne $TagNameObj){
            
            if($PipelineObject.Tags.Values -contains $TagNameObj.TagID ){
                #region Logging existing Tags
                    if($PipelineObject.Tags.Values.Count -gt 0){ Write-Verbose -Message "Existing tags found: $($PipelineObject.Tags.Keys -join ", ")" }
                #endregion
               
                #region Declare variables
                    $DynamicUrl = "{0}" -f $PipelineObject.Url #Base IPAM Endpoint, not manually built because Tags can be used on multiple object types
                    $EnvLabel = $NetBoxSettings.$($Environment).Label

                    $GetDataAttributes = @{
                        Headers     = @{ Authorization = "Token $NetBoxToken" }
                        ContentType = 'application/json; charset=utf-8'
                    }
                #endregion

                #region Build tag array for RestAPI
                    #Build comma separated list with existing tags and new tag
                    $TagIDs = @($PipelineObject.Tags.Values | Where {$_ -ne $TagNameObj.TagID}) -join ","

                    [void]$GetDataAttributes.Add("Body","{`"tags`": [$TagIDs]}")
                #endregion

                #region NetBox API request
                    try{
                        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                        $NetBoxResult = Invoke-RESTMethod -Uri $DynamicUrl @GetDataAttributes -Method Patch -ErrorAction Stop -WarningAction Stop -Verbose:$false

                        Write-Verbose -Message "Successfully removed tag `"$($TagNameObj.Name)`" (TagID$($TagNameObj.TagID)) from $($PipelineObject.Address) (id$($PipelineObject.IPAddressID)) in $EnvLabel" -Verbose
                    }
                    catch{
                        Write-Warning -Message "Error occurred when trying to remove tag `"$($TagNameObj.Name)`" (TagID$($TagNameObj.TagID)) from $($PipelineObject.Address) (id$($PipelineObject.IPAddressID)) in $EnvLabel. Exception: $($_.Exception.Message)"
                    }
                #endregion
            }
            else{
                #No tags found
                Write-Verbose -Message "Tag `"$($TagNameObj.Name)`" (TagID$($TagNameObj.TagID)) is not found on $($PipelineObject.Address) in NetBox $Environment. Nothing to remove"
            }
        }
    }
    End{}
}
