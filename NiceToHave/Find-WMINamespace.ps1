 Function Find-WMINamespace {
    [CmdletBinding()]
    param ($Name)

    $WMIRootNameSpaces = @(Get-WmiObject -Namespace "root" -Class "__Namespace" | Select Name | Sort Name)
    $results = New-Object System.Collections.ArrayList

    $i = 1
    Foreach($WMINameSpace in $WMIRootNameSpaces.Name){
        Write-Verbose "Searching in $WMINameSpace... ($i/$($WMIRootNameSpaces.Count))"
        Get-WmiObject -Namespace $("root\$WMINameSpace") -List | Where {$_.Name -match $Name} | Foreach {
            [void]$results.Add($_)
            Write-Verbose " Found namespace $($_.Name) in $($_.__NAMESPACE.ToLower())"
        }
        $i++
    }
    Write-Verbose "Found $($results.Count) namespaces matching keyword $Name"
    $results
}
