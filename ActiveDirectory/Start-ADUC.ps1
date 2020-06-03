function Start-ADUC {
    [CmdletBinding()]
    Param([Parameter(HelpMessage="Open ADUC from this OU location")][string]$OU)
 
    DynamicParam {
        $ParameterName = 'DC'
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $false
        $ParameterAttribute.Position = 1
        $ParameterAttribute.HelpMessage = 'Target Domain Controller'
        $AttributeCollection.Add($ParameterAttribute)

        $arrSet = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().DomainControllers.Name

        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }

    begin { $DC = $PsBoundParameters[$ParameterName] }

    process {
        $DCString = (([System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name.ToString() -split "\.") | Foreach {"DC=$($_)"}) -join ","
        $dsaString = ""

        if([string]::IsNullOrEmpty($OU)){
            if($OU -match "DC="){ $OU = $OU -replace ",$DCString",'' }
            $dsaString = "/RDN=$OU "
        }
        if($DC){ $dsaString = "$dsaString /SERVER=$DC" }
        
        Start-Process dsa.msc $dsaString
    }
}
