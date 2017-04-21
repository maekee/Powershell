## This PowerShell code can be updated even more with stuff like comment based help, improved credential handling,
## separate parameters for the global variables and so on. But i wanted to share this before i move on to the next assignment so
## everyone that is interested and struggles with this can get some help. Maybe i will come back and fix the missing things.
## Functions creating, updating or deleting returnes True/False if they succeeded or not, so you can use it when calling the function.
## Some of them have verbose logging available, but this can be increased if needed.
## Your feedback and improvements are highly welcome
## Enjoy //Maekee

#Variables used in all functions to authenticate to WebEx
$global:WebExSiteName = 'account.webex.com'
$global:WebExSiteID = '123456'
$global:WebExPartnerID = '123xy'
$global:WebExServiceAccountName = 'webexaccount'
$global:WebExServiceAccountPassword = 'secretpasswordhere'
$global:WebExServiceAccountEmail = 'webexaccount@domain.com'

#Helper functions
Function Add-XMLElement{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)][xml]$XMLBase,
        [Parameter(Mandatory=$true,Position=1)][string]$ElementName,
        [Parameter(Mandatory=$true,Position=2)][string]$ElementValue,
        [Parameter(Mandatory=$false)][string]$ParentName
    )

    $AppendAction = 'Child'
    if(![string]::IsNullOrEmpty($ParentName)){
        if($XMLBase.message.body.bodyContent.$ParentName -eq $null){
            Write-Verbose "Path message.body.bodyContent.$ParentName does not exist, element $ParentName will be added first"
            $AppendAction = "ParentAndChild"
        }
    }

    #Bool input values will be converted to strings, but WebEx API requires that true/false values is
    #in capital letters, and this is what the following line does.
    if($ElementValue -ceq "True" -or $ElementValue -ceq "False"){$ElementValue = $ElementValue.ToUpper()}

    if($AppendAction -eq "Child"){

        if(![string]::IsNullOrEmpty($ParentName)){
            $XMLBaseFullPath = $XMLBase.message.body.bodyContent.$ParentName
            $PathForLogging = "message.body.bodyContent.$ParentName"
        }
        else{
            $XMLBaseFullPath = $XMLBase.message.body.bodyContent
            $PathForLogging = "message.body.bodyContent"
        }

        $NewElement = $XMLBase.CreateElement($ElementName)
        $NewElement.set_InnerText($ElementValue)

        try{
            $XMLBaseFullPath.AppendChild($NewElement) | Out-Null
            Write-Verbose "Successfully added element $ElementName (with value $ElementValue) to $PathForLogging"
            $ReturnedStatus = $true
        }
        catch{
            Write-Warning "Failed to add element $ElementName (with value $ElementValue) to $PathForLogging. Exception: $($_.exception.message)"
            $ReturnedStatus = $false
        }
    }
    else{
        $XMLBaseFullPath = $XMLBase.message.body.bodyContent
        $PathForLogging = "message.body.bodyContent.$ParentName"

        try{
            $XMLNode = $XMLBaseFullPath.AppendChild($XMLBase.CreateElement($ParentName))
            $XMLNode.SetAttribute("id","temporaryvalue");
 
            $XMLChildNode = $XMLNode.AppendChild($XMLBase.CreateElement($ElementName))
            $XMLChildNodeValue = $XMLChildNode.AppendChild($XMLBase.CreateTextNode($ElementValue))

            $XMLNode.RemoveAllAttributes()
            
            Write-Verbose "Successfully added element $ElementName (with value $ElementValue) to $PathForLogging"
            $ReturnedStatus = $true
        }
        catch{
            Write-Warning "Failed to add element $ElementName (with value $ElementValue) to $PathForLogging. Exception: $($_.exception.message)"
            $ReturnedStatus = $false
        }
    }
    
    $ReturnedStatus
}
Function Get-WebExMeetingTypes{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][string]$QueryType,
        [Parameter(Mandatory=$false, Position=0)][string]$SessionValue
    )

    if(![string]::IsNullOrEmpty($SessionValue) -AND [string]::IsNullOrEmpty($QueryType)){$QueryType = "prefix"}
    
    $XMLBody = [xml]"<?xml version=""1.0"" encoding=""UTF-8"" ?>
    <serv:message xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance""
    xmlns:serv=""http://www.webex.com/schemas/2002/06/service"">
    <header>
        <securityContext>
            <webExID>$WebExServiceAccountName</webExID>
            <password>$WebExServiceAccountPassword</password>
            <siteID>$WebExSiteID</siteID>
            <partnerID>$WebExPartnerID</partnerID>
            <email>$WebExServiceAccountEmail</email>
        </securityContext>
    </header>
    <body>
        <bodyContent xsi:type=""java:com.webex.service.binding.meetingtype.LstMeetingType"">
        </bodyContent>
    </body>
    </serv:message>"

    $WebExURL = "https://$WebExSiteName/WBXService/XMLService"

    #region Sending WebRequest and saving respons to URLResponse
        try {
            Write-Verbose "Getting information on WebEx session types"
            $URLResponse = Invoke-WebRequest -Uri $WebExURL -Method Post -ContentType 'text/xml' -TimeoutSec 120 -Body $XMLBody -ErrorAction Stop
        }
        catch { Write-Warning "Failed to send WebEx WebRequest. Exception: $($_.exception.message)" }
    #endregion

    #region Validating WebRequest Status Code and Converting to XML Object
        if($URLResponse.StatusCode -eq 200){
            try{
                $XMLObject = [xml]$URLResponse.Content
                $XMLObject = $XMLObject.message.body.bodyContent.meetingType
            }
            catch{ Write-Warning "Failed to convert returned HTML response to XML. Exception: $($_.exception.message)" }
        }
        else{ Write-Warning "Statuscode $($URLResponse.StatusCode) returned. (StatusDescription $URLResponse.StatusDescription). Expected statuscode 200 (StatusDescription OK)" }
    #endregion

    if([string]::IsNullOrEmpty($XMLObject)){
        $XMLObject = $null
        Write-Verbose "No WebEx session types found"
    }
    else{ Write-Verbose "$($XMLObject.Count) WebEx session types found" }

    #Returning either all meeting types (session types) or meeting type defined in parameter
    if($QueryType -eq "id"){
        if($XMLObject.meetingTypeID -contains $SessionValue){ $XMLObject | Where {$_.meetingTypeID -eq $SessionValue} }
        else{ Write-Warning "Meeting (session) type id $SessionValue not found" }
    }
    elseif($QueryType -eq "prefix"){
        if($XMLObject.productCodePrefix -contains $SessionValue){ $XMLObject | Where {$_.productCodePrefix -eq $SessionValue} }
        else{ Write-Warning "Meeting (session) type name $SessionValue not found" }
    }
    else{ $XMLObject }
}
Function Get-WebExTimeZones{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][string]$QueryType,
        [Parameter(Mandatory=$false, Position=0)][string]$TimeZoneValue
    )

    if(![string]::IsNullOrEmpty($TimeZoneValue) -AND [string]::IsNullOrEmpty($QueryType)){$QueryType = "name"}
    
    $XMLBody = [xml]"<?xml version=""1.0"" encoding=""ISO-8859-1"" ?>
    <serv:message xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance""
    xmlns:serv=""http://www.webex.com/schemas/2002/06/service"">
    <header>
        <securityContext>
            <webExID>$WebExServiceAccountName</webExID>
            <password>$WebExServiceAccountPassword</password>
            <siteID>$WebExSiteID</siteID>
            <partnerID>$WebExPartnerID</partnerID>
            <email>$WebExServiceAccountEmail</email>
        </securityContext>
    </header>
    <body>
        <bodyContent xsi:type=""site.LstTimeZone"">
        </bodyContent>
    </body>
    </serv:message>"

    $WebExURL = "https://$WebExSiteName/WBXService/XMLService"

    #region Sending WebRequest and saving respons to URLResponse
        try {
            Write-Verbose "Getting information on WebEx meeting type $MeetingID..."
            $URLResponse = Invoke-WebRequest -Uri $WebExURL -Method Post -ContentType 'text/xml' -TimeoutSec 120 -Body $XMLBody -ErrorAction Stop
        }
        catch { Write-Warning "Failed to send WebEx WebRequest. Exception: $($_.exception.message)" }
    #endregion

    #region Validating WebRequest Status Code and Converting to XML Object
        if($URLResponse.StatusCode -eq 200){
            try{
                $XMLObject = [xml]$URLResponse.Content
                $XMLObject = $XMLObject.message.body.bodyContent.timeZone
            }
            catch{ Write-Warning "Failed to convert returned HTML response to XML. Exception: $($_.exception.message)" }
        }
        else{ Write-Warning "Statuscode $($URLResponse.StatusCode) returned. (StatusDescription $URLResponse.StatusDescription). Expected statuscode 200 (StatusDescription OK)" }
    #endregion

    if([string]::IsNullOrEmpty($XMLObject)){
        $XMLObject = $null
        Write-Verbose "No WebEx time zones found"
    }
    else{ Write-Verbose "$($XMLObject.Count) WebEx time zones found" }

    #Returning either all timezones or time zone defined in parameter
    if($QueryType -eq "id"){
        if($XMLObject.timeZoneId -contains $TimeZoneValue){ $XMLObject | Where {$_.timeZoneID -eq $TimeZoneValue} }
        else{ Write-Warning "Time zone id $TimeZoneValue not found" }
    }
    elseif($QueryType -eq "name"){
        if($XMLObject.shortName -contains $TimeZoneValue){ $XMLObject | Where {$_.shortName -eq $TimeZoneValue} }
        else{ Write-Warning "Time zone name $TimeZoneValue not found" }
    }
    else{ $XMLObject }
}
Function Get-WebExUser{
    [CmdletBinding()]
    param ([Parameter(Mandatory=$true)][string]$WebExUserID)

    $XMLBody = [xml]"<?xml version=""1.0"" encoding=""UTF-8"" ?>
    <serv:message xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance""
    xmlns:serv=""http://www.webex.com/schemas/2002/06/service"">
    <header>
        <securityContext>
            <webExID>$WebExServiceAccountName</webExID>
            <password>$WebExServiceAccountPassword</password>
            <siteID>$WebExSiteID</siteID>
            <partnerID>$WebExPartnerID</partnerID>
        </securityContext>
    </header>
    <body>
        <bodyContent xsi:type=""java:com.webex.service.binding.user.GetUser"">
            <webExId>$WebExUserID</webExId>
        </bodyContent>
    </body>
    </serv:message>"

    $WebExURL = "https://$WebExSiteName/WBXService/XMLService"

    #region Sending WebRequest and saving respons to URLRespons
        try {
            Write-Verbose "Getting information on WebEx user $WebExUserID..."
            $URLResponse = Invoke-WebRequest -Uri $WebExURL -Method Post -ContentType 'text/xml' -TimeoutSec 120 -Body $XMLBody -ErrorAction Stop
        }
        catch { Write-Warning "Failed to send WebEx WebRequest. Exception: $($_.exception.message)" }
    #endregion

    #region Validating WebRequest Status Code and Converting to XML Object
        if($URLResponse.StatusCode -eq 200){
            try{
                $XMLObject = [xml]$URLResponse.Content
                $XMLObject = $XMLObject.message.body.bodyContent
            }
            catch{ Write-Warning "Failed to convert returned HTML response to XML. Exception: $($_.exception.message)" }
        }
        else{ Write-Warning "Statuscode $($URLResponse.StatusCode) returned. (StatusDescription $URLResponse.StatusDescription). Expected statuscode 200 (StatusDescription OK)" }
    #endregion

    if([string]::IsNullOrEmpty($XMLObject)){
        $XMLObject = $null
        Write-Verbose "No WebEx user found with ID $WebExUserID"
    }
    else{ Write-Verbose "WebEx user $($WebExUserID) found" }
    
    $XMLObject
}
Function Validate-WebExCountry{
    [CmdletBinding()]
    param ([Parameter(Mandatory=$true)][string]$CountryName)
    $CountryArray = ("Afghanistan",
        "Albania",
        "Algeria",
        "American Samoa",
        "Andorra",
        "Angola",
        "Anguilla ",
        "Antarctica",
        "Antigua (including Barbuda)",
        "Argentina",
        "Armenia",
        "Aruba",
        "Ascension Islands",
        "Australia",
        "Austria",
        "Azerbaijan",
        "Bahamas",
        "Bahrain",
        "Bangladesh",
        "Barbados",
        "Belarus",
        "Belgium",
        "Belize",
        "Benin",
        "Bermuda",
        "Bhutan",
        "Bolivia",
        "Bosnia-Herzegovina",
        "Botswana",
        "Brazil",
        "British Virgin Islands",
        "Brunei",
        "Bulgaria",
        "Burkina Faso",
        "Burundi",
        "Cambodia",
        "Cameroon",
        "Canada",
        "Cape Verde Island",
        "Cayman Islands",
        "Central African Republic",
        "Chad Republic",
        "Chile",
        "China",
        "Colombia",
        "Comoros",
        "Congo, Democratic Republic of the Congo",
        "Congo, Republic of the Congo",
        "Cook Islands",
        "Costa Rica",
        "Croatia",
        "Cuba",
        "Cyprus",
        "Czech Republic",
        "Denmark",
        "Diego Garcia",
        "Djibouti",
        "Dominica",
        "Dominican Republic",
        "Ecuador",
        "Egypt outside Cairo",
        "El Salvador",
        "Equatorial Guinea",
        "Eritrea",
        "Estonia",
        "Ethiopia",
        "Faeroe Islands",
        "Falkland Islands",
        "Fiji Islands",
        "Finland",
        "France",
        "French Depts. (Indian Ocean)",
        "French Guiana",
        "French Polynesia",
        "Gabon Republic",
        "Gambia",
        "Georgia",
        "Germany",
        "Ghana",
        "Gibraltar",
        "Greece",
        "Greenland",
        "Grenada",
        "Guadeloupe",
        "Guantanamo (U.S. Naval Base)",
        "Guatemala",
        "Guinea",
        "Guinea-Bissau",
        "Guyana",
        "Haiti",
        "Honduras",
        "Hong Kong",
        "Hungary",
        "Iceland",
        "India",
        "Indonesia",
        "Iran",
        "Iraq",
        "Ireland",
        "Israel",
        "Italy",
        "Ivory Coast",
        "Jamaica",
        "Japan",
        "Jordan",
        "Kazakhstan",
        "Kenya",
        "Kiribati",
        "Korea, North",
        "Korea, South",
        "Kuwait",
        "Kyrgyzstan",
        "Laos",
        "Latvia",
        "Lebanon",
        "Lesotho",
        "Liberia",
        "Libya",
        "Liechtenstein",
        "Lithuania",
        "Luxembourg",
        "Macao",
        "Macedonia",
        "Madagascar",
        "Malawi",
        "Malaysia",
        "Maldives",
        "Mali",
        "Malta",
        "Marshall Islands",
        "Mauritania",
        "Mauritius",
        "Mayotte Island",
        "Mexico",
        "Micronesia",
        "Moldova",
        "Monaco",
        "Mongolia",
        "Montenegro",
        "Montserrat",
        "Morocco",
        "Mozambique",
        "Myanmar",
        "Namibia",
        "Nauru",
        "Nepal",
        "Netherlands",
        "Netherlands Antilles",
        "New Caledonia",
        "New Zealand",
        "Nicaragua",
        "Niger",
        "Nigeria",
        "Niue",
        "Norfolk Island",
        "Northern Mariana Islands",
        "Norway",
        "Oman",
        "Pakistan",
        "Palau",
        "Panama",
        "Papua New Guinea",
        "Paraguay",
        "Peru",
        "Philippines",
        "Poland",
        "Portugal",
        "Puerto Rico",
        "Qatar",
        "Romania",
        "Russia",
        "Rwanda",
        "San Marino",
        "Sao Tome",
        "Saudi Arabia",
        "Senegal Republic",
        "Serbia",
        "Seychelles Islands",
        "Sierra Leone",
        "Singapore",
        "Slovakia",
        "Slovenia",
        "Solomon Islands",
        "Somalia",
        "South Africa",
        "Spain",
        "Sri Lanka",
        "St Helena",
        "St Kitts and Nevis ",
        "St Lucia",
        "St Pierre and Miquelon",
        "St Vincent",
        "Sudan",
        "Suriname",
        "Swaziland",
        "Sweden",
        "Switzerland",
        "Syria",
        "Taiwan",
        "Tajikistan",
        "Tanzania",
        "Thailand",
        "Togo",
        "Tonga Islands",
        "Trinidad and Tobago",
        "Tunisia",
        "Turkey",
        "Turkmenistan",
        "Turks and Caicos",
        "Tuvalu",
        "Uganda",
        "Ukraine",
        "United Arab Emirates",
        "United Kingdom",
        "United States of America",
        "Uruguay",
        "Uzbekistan",
        "Vanuatu",
        "Vatican City",
        "Venezuela",
        "Vietnam",
        "Wallis And Futuna Islands",
        "Western Samoa",
        "Yemen",
        "Zambia",
        "Zimbabwe")

    if($CountryArray -contains $CountryName){$true}
    else{
        $FirstLetter = ($CountryName.Substring(0,1)).ToUpper()
        $CountryListWithFirstLetter = $CountryArray -match "^$FirstLetter"
        if($CountryListWithFirstLetter.Count -gt 0){
            Write-Verbose "The following $($CountryListWithFirstLetter.Count) countries start with the letter $($FirstLetter):"
            $CountryListWithFirstLetter | Foreach { Write-Verbose "$_" }
        }
        else{ Write-Verbose "No countries do not even start with $FirstLetter" }
        $false
    }
}

Function Get-WebExUserRecordings{
    [CmdletBinding()]
    param ([Parameter(Mandatory=$true)][string]$WebExUserID)

    $XMLBody =[xml]"<?xml version=""1.0"" encoding=""UTF-8"" ?>
    <serv:message xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance""
    xmlns:serv=""http://www.webex.com/schemas/2002/06/service"">
    <header>
        <securityContext>
            <webExID>$WebExServiceAccountName</webExID>
            <password>$WebExServiceAccountPassword</password>
            <siteID>$WebExSiteID</siteID>
            <partnerID>$WebExPartnerID</partnerID>
        </securityContext>
    </header>
    <body>
        <bodyContent xsi:type=""java:com.webex.service.binding.ep.LstRecording"">
            <listControl>
                <startFrom>0</startFrom>
                <maximumNum>10000</maximumNum>
            </listControl>
            <hostWebExID>$WebExUserID</hostWebExID>
        </bodyContent>
    </body>
    </serv:message>"

    $WebExURL = "https://$WebExSiteName/WBXService/XMLService"

    #region Sending WebRequest and saving respons to URLRespons
        try {
            Write-Verbose "Getting information on WebEx recordings..."
            $URLResponse = Invoke-WebRequest -Uri $WebExURL -Method Post -ContentType 'text/xml' -TimeoutSec 120 -Body $XMLBody -ErrorAction Stop
        }
        catch { Write-Warning "Failed to send WebEx WebRequest. Exception: $($_.exception.message)" }
    #endregion

    #region Validating WebRequest Status Code and Converting to XML Object
        if($URLResponse.StatusCode -eq 200){
            try{
                $XMLObject = [xml]$URLResponse.Content
                if([string]::IsNullOrEmpty($XMLObject.message.body.bodyContent)){ $XMLObject = $null }
                else{ $XMLObject = $XMLObject.message.body.bodyContent.recording }
            }
            catch{ Write-Warning "Failed to convert returned HTML response to XML. Exception: $($_.exception.message)" }
        }
        else{ Write-Warning "Statuscode $($URLResponse.StatusCode) returned. (StatusDescription $URLResponse.StatusDescription). Expected statuscode 200 (StatusDescription OK)" }
    #endregion

    if([string]::IsNullOrEmpty($XMLObject)){
        $XMLObject = $null
        Write-Verbose "No WebEx recordings found for user $WebExUserID"
    }
    else{ Write-Verbose "$($XMLObject.Count) WebEx recordings for user $($WebExUserID) found" }

    $XMLObject
}
Function Remove-WebExUserRecoding{
    [CmdletBinding()]
    param ([Parameter(Mandatory=$true)][string]$RecordingID)

    $XMLBody =[xml]"<?xml version=""1.0"" encoding=""UTF-8"" ?>
    <serv:message xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance""
    xmlns:serv=""http://www.webex.com/schemas/2002/06/service"">
    <header>
        <securityContext>
            <webExID>$WebExServiceAccountName</webExID>
            <password>$WebExServiceAccountPassword</password>
            <siteID>$WebExSiteID</siteID>
            <partnerID>$WebExPartnerID</partnerID>
        </securityContext>
    </header>
    <body>
        <bodyContent
            xsi:type=""java:com.webex.service.binding.ep.DelRecording"">
            <recordingID>$RecordingID</recordingID>
        </bodyContent>
    </body>
    </serv:message>"

    $WebExURL = "https://$WebExSiteName/WBXService/XMLService"
    
    #region Sending WebRequest and saving respons to URLRespons
        try {
            Write-Verbose "Sending WebRequest to remove WebEx recoding $RecordingID..."
            $URLResponse = Invoke-WebRequest -Uri $WebExURL -Method Post -ContentType 'text/xml' -TimeoutSec 120 -Body $XMLBody -ErrorAction Stop
        }
        catch { Write-Warning "Failed to send WebEx WebRequest. Exception: $($_.exception.message)" }
    #endregion

    #region Validating WebRequest Status Code and results
        if($URLResponse.StatusCode -eq 200){
            try{
                $XMLObject = [xml]$URLResponse.Content

                if($XMLObject.ChildNodes.header.response.result -eq "SUCCESS"){
                    Write-Verbose "Successfully removed WebEx recoding with ID $RecordingID"
                    $ResultToReturn = $true
                }
                else {
                    Write-Warning "Webex returned result $($XMLObject.ChildNodes.header.response.result), reason: $($XMLObject.ChildNodes.header.response.reason)"
                    $ResultToReturn = $false
                }
            }
            catch{
                Write-Warning "Failed to convert returned HTML response to XML. Exception: $($_.exception.message)"
                $ResultToReturn = $false
            }
        }
        else{
            Write-Warning "Statuscode $($URLResponse.StatusCode) returned. (StatusDescription $URLResponse.StatusDescription). Expected statuscode 200 (StatusDescription OK)"
            $ResultToReturn = $false
        }
    #endregion

    $ResultToReturn
}
Function Disable-WebExUser{
    [CmdletBinding()]
    param ([Parameter(Mandatory=$true)][string]$WebExUserID)

    $XMLBody = [xml]"<?xml version=""1.0"" encoding=""UTF-8"" ?>
    <serv:message xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance""
    xmlns:serv=""http://www.webex.com/schemas/2002/06/service"">
    <header>
        <securityContext>
            <webExID>$WebExServiceAccountName</webExID>
            <password>$WebExServiceAccountPassword</password>
            <siteID>$WebExSiteID</siteID>
            <partnerID>$WebExPartnerID</partnerID>
        </securityContext>
    </header>
    <body>
        <bodyContent xsi:type=""java:com.webex.service.binding.user.SetUser"">
            <webExId>$WebExUserID</webExId>
            <active>DEACTIVATED</active>
        </bodyContent>
    </body>
    </serv:message>"

    $WebExURL = "https://$WebExSiteName/WBXService/XMLService"

    #region Sending WebRequest and saving respons to URLRespons
        try {
            Write-Verbose "Sending WebRequest to disable WebEx user $WebExUserID..."
            $URLResponse = Invoke-WebRequest -Uri $WebExURL -Method Post -ContentType 'text/xml' -TimeoutSec 120 -Body $XMLBody -ErrorAction Stop
        }
        catch { Write-Warning "Failed to send WebEx WebRequest. Exception: $($_.exception.message)" }
    #endregion

    #region Validating WebRequest Status Code and results
        if($URLResponse.StatusCode -eq 200){
            try{
                $XMLObject = [xml]$URLResponse.Content

                if($XMLObject.ChildNodes.header.response.result -eq "SUCCESS"){
                    Write-Verbose "Successfully disabled WebEx user $WebExUserID"
                    $ResultToReturn = $true
                }
                else {
                    Write-Warning "Webex returned result $($XMLObject.ChildNodes.header.response.result), reason: $($XMLObject.ChildNodes.header.response.reason)"
                    $ResultToReturn = $false
                }
            }
            catch{
                Write-Warning "Failed to convert returned HTML response to XML. Exception: $($_.exception.message)"
                $ResultToReturn = $false
            }
        }
        else{
            Write-Warning "Statuscode $($URLResponse.StatusCode) returned. (StatusDescription $URLResponse.StatusDescription). Expected statuscode 200 (StatusDescription OK)"
            $ResultToReturn = $false
        }
    #endregion

    $ResultToReturn
}
Function Enable-WebExUser{
    [CmdletBinding()]
    param ([Parameter(Mandatory=$true)][string]$WebExUserID)

    $XMLBody = [xml]"<?xml version=""1.0"" encoding=""UTF-8"" ?>
    <serv:message xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance""
    xmlns:serv=""http://www.webex.com/schemas/2002/06/service"">
    <header>
        <securityContext>
            <webExID>$WebExServiceAccountName</webExID>
            <password>$WebExServiceAccountPassword</password>
            <siteID>$WebExSiteID</siteID>
            <partnerID>$WebExPartnerID</partnerID>
        </securityContext>
    </header>
    <body>
        <bodyContent xsi:type=""java:com.webex.service.binding.user.SetUser"">
            <webExId>$WebExUserID</webExId>
            <active>ACTIVATED</active>
        </bodyContent>
    </body>
    </serv:message>"

    $WebExURL = "https://$WebExSiteName/WBXService/XMLService"

    #region Sending WebRequest and saving respons to URLRespons
        try {
            Write-Verbose "Sending WebRequest to enable WebEx user $WebExUserID..."
            $URLResponse = Invoke-WebRequest -Uri $WebExURL -Method Post -ContentType 'text/xml' -TimeoutSec 120 -Body $XMLBody -ErrorAction Stop
        }
        catch { Write-Warning "Failed to send WebEx WebRequest. Exception: $($_.exception.message)" }
    #endregion

    #region Validating WebRequest Status Code and results
        if($URLResponse.StatusCode -eq 200){
            try{
                $XMLObject = [xml]$URLResponse.Content

                if($XMLObject.ChildNodes.header.response.result -eq "SUCCESS"){
                    Write-Verbose "Successfully enabled WebEx user $WebExUserID"
                    $ResultToReturn = $true
                }
                else {
                    Write-Warning "Webex returned result $($XMLObject.ChildNodes.header.response.result), reason: $($XMLObject.ChildNodes.header.response.reason)"
                    $ResultToReturn = $false
                }
            }
            catch{
                Write-Warning "Failed to convert returned HTML response to XML. Exception: $($_.exception.message)"
                $ResultToReturn = $false
            }
        }
        else{
            Write-Warning "Statuscode $($URLResponse.StatusCode) returned. (StatusDescription $URLResponse.StatusDescription). Expected statuscode 200 (StatusDescription OK)"
            $ResultToReturn = $false
        }
    #endregion

    $ResultToReturn
}
Function Create-WebExUser{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][string]$WebExUserID,
        #region Account Information (Mandatory parameters)
            [Parameter(Mandatory=$true)][string]$FirstName,
            [Parameter(Mandatory=$true)][string]$LastName,
            [Parameter(Mandatory=$true)][string]$EmailAddress,
            [Parameter(Mandatory=$false)]$TimeZoneValue,
            [Parameter(Mandatory=$true)][string]$password,
        #endregion
        #region Contact Information
            [Parameter(Mandatory=$false)][string]$AddressLine1,
            [Parameter(Mandatory=$false)][string]$AddressLine2,
            [Parameter(Mandatory=$false)][string]$City,
            [Parameter(Mandatory=$false)][string]$State_Province,
            [Parameter(Mandatory=$false)][string]$ZipCode,
            [Parameter(Mandatory=$false)][string]$Country
        #endregion
    )

    $XMLBody = [xml]"<?xml version=""1.0"" encoding=""UTF-8""?>
    <serv:message xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance""
        xmlns:serv=""http://www.webex.com/schemas/2002/06/service"">
        <header>
            <securityContext>
                <webExID>$WebExServiceAccountName</webExID>
                <password>$WebExServiceAccountPassword</password>
                <siteID>$WebExSiteID</siteID>
                <partnerID>$WebExPartnerID</partnerID>
            </securityContext>
        </header>
        <body>
            <bodyContent
                xsi:type=""java:com.webex.service.binding.user.CreateUser"">
                <webExId>$WebExUserID</webExId>
                <firstName>$FirstName</firstName>
                <lastName>$LastName</lastName>
                <email>$EmailAddress</email>
                <password>$password</password>
                <privilege>
                    <host>true</host>
                </privilege>
                <active>ACTIVATED</active>
            </bodyContent>
        </body>
    </serv:message>"

    $WebExURL = "https://$WebExSiteName/WBXService/XMLService"

    #region Adding XML Elements for used parameters
        try{
            #region bodyContent
                if(![string]::IsNullOrEmpty($TimeZoneValue)){
                    try{ $ValueToUse = [int]::Parse($TimeZoneValue) ; $parsestatus = $true }
                    catch{ $ValueToUse = $TimeZoneValue ; $parsestatus = $false }

                    if($parsestatus){ $TimeZoneObj = Get-WebExTimeZones -QueryType "id" -TimeZoneValue $ValueToUse }
                    else{ $TimeZoneObj = Get-WebExTimeZones -QueryType "name" -TimeZoneValue $ValueToUse }

                    if($TimeZoneObj -ne $null){ Add-XMLElement -XMLBase $XMLBody -ElementName "timeZoneID" -ElementValue $TimeZoneObj.timeZoneID | Out-Null }
                    else{ Write-Verbose "No valid timezone found based on value $TimeZoneValue, validate name or id against approved list. Time zone will be skipped." }
                }
            #endregion
            #region bodyContent.address
                if(![string]::IsNullOrEmpty($AddressLine1)){ Add-XMLElement -XMLBase $XMLBody -ElementName "address1" -ElementValue $AddressLine1 -ParentName "address" | Out-Null }
                if(![string]::IsNullOrEmpty($AddressLine2)){ Add-XMLElement -XMLBase $XMLBody -ElementName "address2" -ElementValue $AddressLine2 -ParentName "address" | Out-Null }
                if(![string]::IsNullOrEmpty($City)){ Add-XMLElement -XMLBase $XMLBody -ElementName "city" -ElementValue $City -ParentName "address" | Out-Null }
                if(![string]::IsNullOrEmpty($State_Province)){ Add-XMLElement -XMLBase $XMLBody -ElementName "state" -ElementValue $State_Province -ParentName "address" | Out-Null }
                if(![string]::IsNullOrEmpty($ZipCode)){ Add-XMLElement -XMLBase $XMLBody -ElementName "zipCode" -ElementValue $ZipCode -ParentName "address" | Out-Null }
                if(![string]::IsNullOrEmpty($Country)){
                    if(Validate-WebExCountry -CountryName $Country){ Add-XMLElement -XMLBase $XMLBody -ElementName "country" -ElementValue $Country -ParentName "address" | Out-Null }
                    else{ Write-Warning "Country $Country not found, no country will be modified" }
                }
            #endregion
        }
        catch{ Write-Warning "Error occurred while adding data to XML. Exception: $($_.exception.message)" }
    #endregion

    #region Sending WebRequest and saving respons to URLRespons
        try {
            Write-Verbose "Sending WebRequest to create WebEx user $WebExUserID..."
            $URLResponse = Invoke-WebRequest -Uri $WebExURL -Method Post -ContentType 'text/xml' -TimeoutSec 120 -Body $XMLBody -ErrorAction Stop
        }
        catch { Write-Warning "Failed to send WebEx WebRequest. Exception: $($_.exception.message)" }
    #endregion

    #region Validating WebRequest Status Code and results
        if($URLResponse.StatusCode -eq 200){
            try{
                $XMLObject = [xml]$URLResponse.Content

                if($XMLObject.ChildNodes.header.response.result -eq "SUCCESS"){
                    Write-Verbose "Successfully disabled WebEx user $WebExUserID"
                    $ResultToReturn = $true
                }
                else {
                    Write-Warning "Webex returned result $($XMLObject.ChildNodes.header.response.result), reason: $($XMLObject.ChildNodes.header.response.reason)"
                    $ResultToReturn = $false
                }
            }
            catch{
                Write-Warning "Failed to convert returned HTML response to XML. Exception: $($_.exception.message)"
                $ResultToReturn = $false
            }
        }
        else{
            Write-Warning "Statuscode $($URLResponse.StatusCode) returned. (StatusDescription $URLResponse.StatusDescription). Expected statuscode 200 (StatusDescription OK)"
            $ResultToReturn = $false
        }
    #endregion

    $ResultToReturn
}
Function Edit-WebExUser{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][string]$WebExUserID,
        #region Account Information
            [Parameter(Mandatory=$false)][string]$FirstName,
            [Parameter(Mandatory=$false)][string]$LastName,
            [Parameter(Mandatory=$false)][string]$EmailAddress,
            [Parameter(Mandatory=$false)]$TimeZoneValue,
        #endregion
        #region Contact Information
            [Parameter(Mandatory=$false)][string]$AddressLine1,
            [Parameter(Mandatory=$false)][string]$AddressLine2,
            [Parameter(Mandatory=$false)][string]$City,
            [Parameter(Mandatory=$false)][string]$State_Province,
            [Parameter(Mandatory=$false)][string]$ZipCode,
            [Parameter(Mandatory=$false)][string]$Country,
        #endregion
        #region Privileges
            [Parameter(Mandatory=$false)][boolean]$ForceChangePasswordOnNextLogin,
            [Parameter(Mandatory=$false)][boolean]$LockAccount,
            [Parameter(Mandatory=$false)][boolean]$UnlockAccount,
            [Parameter(Mandatory=$false)][boolean]$EnableRecordingEditor,
            [Parameter(Mandatory=$false)][boolean]$DisableRecordingEditor,
            [Parameter(Mandatory=$false)][ValidateSet('HQ360p','HQ360p-HD720p','OFF')][string]$HighQualityVideoMode,
            [Parameter(Mandatory=$false)][boolean]$EnableCollaborationMeetingRoom,
            [Parameter(Mandatory=$false)][boolean]$DisableCollaborationMeetingRoom,
        #endregion
        #region My WebEx
            [Parameter(Mandatory=$false)][ValidateSet('Standard','Pro')][string]$MyWebExType
        #endregion
    )

    [xml]$XMLBody = "<?xml version=""1.0"" encoding=""UTF-8"" ?>
    <serv:message xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance""
    xmlns:serv=""http://www.webex.com/schemas/2002/06/service"">
    <header>
        <securityContext>
            <webExID>$WebExServiceAccountName</webExID>
            <password>$WebExServiceAccountPassword</password>
            <siteID>$WebExSiteID</siteID>
            <partnerID>$WebExPartnerID</partnerID>
        </securityContext>
    </header>
    <body>
        <bodyContent xsi:type=""java:com.webex.service.binding.user.SetUser"">
            <webExId>$WebExUserID</webExId>
        </bodyContent>
    </body>
    </serv:message>"

    $WebExURL = "https://$WebExSiteName/WBXService/XMLService"

    #region Adding XML Elements for used parameters
        try{
            #region bodyContent
                if(![string]::IsNullOrEmpty($FirstName)){ Add-XMLElement -XMLBase $XMLBody -ElementName "firstName" -ElementValue $FirstName | Out-Null }
                if(![string]::IsNullOrEmpty($LastName)){ Add-XMLElement -XMLBase $XMLBody -ElementName "lastName" -ElementValue $LastName | Out-Null }
                if(![string]::IsNullOrEmpty($EmailAddress)){ Add-XMLElement -XMLBase $XMLBody -ElementName "email" -ElementValue $EmailAddress | Out-Null }
                if(![string]::IsNullOrEmpty($TimeZoneValue)){
                    try{ $ValueToUse = [int]::Parse($TimeZoneValue) ; $parsestatus = $true }
                    catch{ $ValueToUse = $TimeZoneValue ; $parsestatus = $false }

                    if($parsestatus){ $TimeZoneObj = Get-WebExTimeZones -QueryType "id" -TimeZoneValue $ValueToUse }
                    else{ $TimeZoneObj = Get-WebExTimeZones -QueryType "name" -TimeZoneValue $ValueToUse }

                    if($TimeZoneObj -ne $null){ Add-XMLElement -XMLBase $XMLBody -ElementName "timeZoneID" -ElementValue $TimeZoneObj.timeZoneID | Out-Null }
                    else{ Write-Verbose "No valid timezone found based on value $TimeZoneValue, validate name or id against approved list. Time zone will be skipped." }
                }
            #endregion
            #region bodyContent.address
                if(![string]::IsNullOrEmpty($AddressLine1)){ Add-XMLElement -XMLBase $XMLBody -ElementName "address1" -ElementValue $AddressLine1 -ParentName "address" | Out-Null }
                if(![string]::IsNullOrEmpty($AddressLine2)){ Add-XMLElement -XMLBase $XMLBody -ElementName "address2" -ElementValue $AddressLine2 -ParentName "address" | Out-Null }
                if(![string]::IsNullOrEmpty($City)){ Add-XMLElement -XMLBase $XMLBody -ElementName "city" -ElementValue $City -ParentName "address" | Out-Null }
                if(![string]::IsNullOrEmpty($State_Province)){ Add-XMLElement -XMLBase $XMLBody -ElementName "state" -ElementValue $State_Province -ParentName "address" | Out-Null }
                if(![string]::IsNullOrEmpty($ZipCode)){ Add-XMLElement -XMLBase $XMLBody -ElementName "zipCode" -ElementValue $ZipCode -ParentName "address" | Out-Null }
                if(![string]::IsNullOrEmpty($Country)){
                    if(Validate-WebExCountry -CountryName $Country){ Add-XMLElement -XMLBase $XMLBody -ElementName "country" -ElementValue $Country -ParentName "address" | Out-Null }
                    else{ Write-Warning "Country $Country not found, no country will be modified" }
                }
            #endregion
            #region bodyContent.security
                if($ForceChangePasswordOnNextLogin){ Add-XMLElement -XMLBase $XMLBody -ElementName "forceChangePassword" -ElementValue $ForceChangePasswordOnNextLogin -ParentName "security" | Out-Null }
                if($LockAccount -and $UnlockAccount){ Write-Warning "You cannot lock and unlock the account at the same time, nothing will be done" }
                else{
                    if($LockAccount){ Add-XMLElement -XMLBase $XMLBody -ElementName "lockAccount" -ElementValue "TRUE" -ParentName "security" | Out-Null }
                    if($UnlockAccount){ Add-XMLElement -XMLBase $XMLBody -ElementName "lockAccount" -ElementValue "FALSE" -ParentName "security" | Out-Null }
                }
            #endregion
            #region bodyContent.privilege
                if($EnableRecordingEditor -and $DisableRecordingEditor){ Write-Warning "You cannot enable and disable recording editor at the same time, nothing will be done" }
                else{
                    if($EnableRecordingEditor){ Add-XMLElement -XMLBase $XMLBody -ElementName "recordingEditor" -ElementValue "TRUE" -ParentName "privilege" | Out-Null }
                    if($DisableRecordingEditor){ Add-XMLElement -XMLBase $XMLBody -ElementName "recordingEditor" -ElementValue "FALSE" -ParentName "privilege" | Out-Null }
                }
                if(![string]::IsNullOrEmpty($HighQualityVideoMode)){
                    if($HighQualityVideoMode -eq 'HQ360p'){
                        Add-XMLElement -XMLBase $XMLBody -ElementName "HQvideo" -ElementValue "TRUE" -ParentName "privilege" | Out-Null
                        Add-XMLElement -XMLBase $XMLBody -ElementName "HDvideo" -ElementValue "FALSE" -ParentName "privilege" | Out-Null
                    }
                    elseif($HighQualityVideoMode -eq 'HQ360p-HD720p'){
                        Add-XMLElement -XMLBase $XMLBody -ElementName "HQvideo" -ElementValue "TRUE" -ParentName "privilege" | Out-Null
                        Add-XMLElement -XMLBase $XMLBody -ElementName "HDvideo" -ElementValue "TRUE" -ParentName "privilege" | Out-Null
                    }
                    elseif($HighQualityVideoMode -eq 'OFF'){
                        Add-XMLElement -XMLBase $XMLBody -ElementName "HQvideo" -ElementValue "FALSE" -ParentName "privilege" | Out-Null
                        Add-XMLElement -XMLBase $XMLBody -ElementName "HDvideo" -ElementValue "FALSE" -ParentName "privilege" | Out-Null
                    }
                }
                if($EnableCollaborationMeetingRoom -and $DisableCollaborationMeetingRoom){ Write-Warning "You cannot enable and disable collaboration meeting room at the same time, nothing will be done" }
                else{
                    if($EnableCollaborationMeetingRoom){ Add-XMLElement -XMLBase $XMLBody -ElementName "isEnableCET" -ElementValue "TRUE" -ParentName "privilege" | Out-Null }
                    if($DisableCollaborationMeetingRoom){ Add-XMLElement -XMLBase $XMLBody -ElementName "isEnableCET" -ElementValue "FALSE" -ParentName "privilege" | Out-Null }
                }
            #endregion
            #region bodyContent.myWebEx
                if(![string]::IsNullOrEmpty($MyWebExType)){
                    if($MyWebExType -eq 'Standard'){ Add-XMLElement -XMLBase $XMLBody -ElementName "isMyWebExPro" -ElementValue "FALSE" -ParentName "myWebEx" | Out-Null }
                    elseif($MyWebExType -eq 'Pro'){
                        Add-XMLElement -XMLBase $XMLBody -ElementName "isMyWebExPro" -ElementValue "TRUE" -ParentName "myWebEx" | Out-Null
                        #These three features below enables: "My Files: Training Recordings", "My Files: Event Recordings" and "My Reports"
                        Add-XMLElement -XMLBase $XMLBody -ElementName "trainingRecordings" -ElementValue "TRUE" -ParentName "myWebEx" | Out-Null
                        Add-XMLElement -XMLBase $XMLBody -ElementName "recordedEvents" -ElementValue "TRUE" -ParentName "myWebEx" | Out-Null
                        Add-XMLElement -XMLBase $XMLBody -ElementName "myReports" -ElementValue "TRUE" -ParentName "myWebEx" | Out-Null
                    }
                }
            #endregion
        }
        catch{ Write-Warning "Error occurred while adding data to XML. Exception: $($_.exception.message)" }
    #endregion

    #region Sending WebRequest and saving respons to URLRespons
        try {
            Write-Verbose "Sending WebRequest to update WebEx user $WebExUserID..."
            $URLResponse = Invoke-WebRequest -Uri $WebExURL -Method Post -ContentType 'text/xml' -TimeoutSec 120 -Body $XMLBody -ErrorAction Stop
        }
        catch { Write-Warning "Failed to send WebEx WebRequest. Exception: $($_.exception.message)" }
    #endregion

    #region Validating WebRequest Status Code and results
        if($URLResponse.StatusCode -eq 200){
            try{
                $XMLObject = [xml]$URLResponse.Content

                if($XMLObject.ChildNodes.header.response.result -eq "SUCCESS"){
                    Write-Verbose "Successfully updated WebEx user $WebExUserID"
                    $ResultToReturn = $true
                }
                else {
                    Write-Warning "Webex returned result $($XMLObject.ChildNodes.header.response.result), reason: $($XMLObject.ChildNodes.header.response.reason)"
                    $ResultToReturn = $false
                }
            }
            catch{
                Write-Warning "Failed to convert returned HTML response to XML. Exception: $($_.exception.message)"
                $ResultToReturn = $false
            }
        }
        else{
            Write-Warning "Statuscode $($URLResponse.StatusCode) returned. (StatusDescription $URLResponse.StatusDescription). Expected statuscode 200 (StatusDescription OK)"
            $ResultToReturn = $false
        }
    #endregion

    $ResultToReturn
}
Function Reset-WebExUserPassword{
    [CmdletBinding()]
    param ([Parameter(Mandatory=$true)][string]$WebExUserID)

    [xml]$XMLBody = "<?xml version=""1.0"" encoding=""UTF-8"" ?>
    <serv:message xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance""
    xmlns:serv=""http://www.webex.com/schemas/2002/06/service"">
    <header>
        <securityContext>
            <webExID>$WebExServiceAccountName</webExID>
            <password>$WebExServiceAccountPassword</password>
            <siteID>$WebExSiteID</siteID>
            <partnerID>$WebExPartnerID</partnerID>
        </securityContext>
    </header>
    <body>
        <bodyContent xsi:type=""java:com.webex.service.binding.user.SetUser"">
            <webExId>$WebExUserID</webExId>
                <security>
                    <resetPassword>TRUE</resetPassword>
                </security>
        </bodyContent>
    </body>
    </serv:message>"

    $WebExURL = "https://$WebExSiteName/WBXService/XMLService"
    
    #region Sending WebRequest and saving respons to URLRespons
        try {
            Write-Verbose "Sending WebRequest to reset WebEx password for user $WebExUserID..."
            $URLResponse = Invoke-WebRequest -Uri $WebExURL -Method Post -ContentType 'text/xml' -TimeoutSec 120 -Body $XMLBody -ErrorAction Stop
        }
        catch { Write-Warning "Failed to send WebEx WebRequest. Exception: $($_.exception.message)" }
    #endregion

    #region Validating WebRequest Status Code and results
        if($URLResponse.StatusCode -eq 200){
            try{
                $XMLObject = [xml]$URLResponse.Content

                if($XMLObject.ChildNodes.header.response.result -eq "SUCCESS"){
                    Write-Verbose "Successfully enabled WebEx user $WebExUserID"
                    $ResultToReturn = $true
                }
                else {
                    Write-Warning "Webex returned result $($XMLObject.ChildNodes.header.response.result), reason: $($XMLObject.ChildNodes.header.response.reason)"
                    $ResultToReturn = $false
                }
            }
            catch{
                Write-Warning "Failed to convert returned HTML response to XML. Exception: $($_.exception.message)"
                $ResultToReturn = $false
            }
        }
        else{
            Write-Warning "Statuscode $($URLResponse.StatusCode) returned. (StatusDescription $URLResponse.StatusDescription). Expected statuscode 200 (StatusDescription OK)"
            $ResultToReturn = $false
        }
    #endregion

    $ResultToReturn
}
Function Change-WebExUserPassword{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][string]$WebExUserID,
        [Parameter(Mandatory=$true)][string]$password
    )

    [xml]$XMLBody = "<?xml version=""1.0"" encoding=""UTF-8"" ?>
    <serv:message xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance""
    xmlns:serv=""http://www.webex.com/schemas/2002/06/service"">
    <header>
        <securityContext>
            <webExID>$WebExServiceAccountName</webExID>
            <password>$WebExServiceAccountPassword</password>
            <siteID>$WebExSiteID</siteID>
            <partnerID>$WebExPartnerID</partnerID>
        </securityContext>
    </header>
    <body>
        <bodyContent xsi:type=""java:com.webex.service.binding.user.SetUser"">
            <webExId>$WebExUserID</webExId>
            <password>$password</password>
        </bodyContent>
    </body>
    </serv:message>"

    $WebExURL = "https://$WebExSiteName/WBXService/XMLService"
    
    #region Sending WebRequest and saving respons to URLRespons
        try {
            Write-Verbose "Sending WebRequest to reset WebEx password for user $WebExUserID..."
            $URLResponse = Invoke-WebRequest -Uri $WebExURL -Method Post -ContentType 'text/xml' -TimeoutSec 120 -Body $XMLBody -ErrorAction Stop
        }
        catch { Write-Warning "Failed to send WebEx WebRequest. Exception: $($_.exception.message)" }
    #endregion

    #region Validating WebRequest Status Code and results
        if($URLResponse.StatusCode -eq 200){
            try{
                $XMLObject = [xml]$URLResponse.Content

                if($XMLObject.ChildNodes.header.response.result -eq "SUCCESS"){
                    Write-Verbose "Successfully enabled WebEx user $WebExUserID"
                    $ResultToReturn = $true
                }
                else {
                    Write-Warning "Webex returned result $($XMLObject.ChildNodes.header.response.result), reason: $($XMLObject.ChildNodes.header.response.reason)"
                    $ResultToReturn = $false
                }
            }
            catch{
                Write-Warning "Failed to convert returned HTML response to XML. Exception: $($_.exception.message)"
                $ResultToReturn = $false
            }
        }
        else{
            Write-Warning "Statuscode $($URLResponse.StatusCode) returned. (StatusDescription $URLResponse.StatusDescription). Expected statuscode 200 (StatusDescription OK)"
            $ResultToReturn = $false
        }
    #endregion

    $ResultToReturn
}
