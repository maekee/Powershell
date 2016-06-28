Function Run-SQLCommand{
<#
.SYNOPSIS
    Used to query SQL databases
.DESCRIPTION
    Use this function to query SQL databases. The function uses the credentials of the account
    that runs the script (Integrated Security).
.PARAMETER SQLServer
    The name of the SQL Server
.PARAMETER Database
    The name of the database on the SQL Server
.PARAMETER SQLQuery
    The Query to run against the database on the SQL Server
.EXAMPLE
    Get all Employees from HRSystem

    Run-SQLCommand -SQLServer SQLSERVER1 -Database HRDatabase -SQLQuery 'SELECT Name,EmployeeID FROM HRSystem'
.EXAMPLE
    Get all Employees from HRSystem with Titles joined in from HRSystemTitles with a
    multiline SQL Query and stores the result in the variable $HRPersonelContent.

    $SQLQueryToExecute = @'
    SELECT HR.EmployeeName,Titles.Title
    FROM
    HRSystemTable AS HR
    INNER JOIN HRSystemTitles AS Titles ON Titles.ID = HR.ID
    WHERE Titles.Title = 'Manager'
    ORDER BY HR.EmployeeName
    '@

    $HRPersonelContent = Run-SQLCommand -SQLServer SQLSERVER1 -Database HRDatabase -SQLQuery $SQLQueryToExecute
.NOTES
    Script name: Run-SQLCommand
    Author:      Micke Sundqvist
    Twitter:     @mickesunkan
    Github:      https://github.com/maekee/Powershell
#>
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true)]
        [string]$SQLServer,
        [parameter(Mandatory=$true)]
        [string]$Database,
        [parameter(Mandatory=$true)]
        [string]$SQLQuery
    )
	TRY{
	    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	    $SqlConnection.ConnectionString = "Server=$SQLServer;Database=$Database;Integrated Security=True;" 
	    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	    $SqlCmd.CommandText = $SQLQuery
	    $SqlCmd.Connection = $SqlConnection
	    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
	    $SqlAdapter.SelectCommand = $SqlCmd
	    $DataSet = New-Object System.Data.DataSet
	    $nSet = $SqlAdapter.Fill($DataSet)
	    $OutputTable = $DataSet.Tables[0]
	    $SqlConnection.Close();
	    Return $OutputTable
    }
    CATCH{ Write-Warning $_.Exception.Message }
}
