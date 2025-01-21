# Function to identify if user is logged on to Windows and if computer is locked or not
# Code has not been tested if computer is not signed in, but LoggedOnUserData should return NULL in that case (maybe SYSTEM?)

Function Get-WindowsComputerState{
    [CmdletBinding()]
    param(
        [ValidateSet("LoggedOn","Locked","All")]$ReturnType = "All"
    )

    #region LoggedOnUser
        try{
            $LoggedOnUserData = ((Get-CimInstance -Class Win32_LoggedOnUser -ErrorAction Stop).Antecedent.Name)

            if($null -eq $LoggedOnUserData){
                $UserPresent = $false
                $UserData = $null
            }
            else{
                $UserPresent = $true
                $UserData = $LoggedOnUserData
            }
        }
        catch{
            $UserPresent = "ERROR"
            $UserData = "ERROR"
        }
    #endregion

    #region LogonUI (locked)
        try{
            $LogonUIPresent = Get-CimInstance -Query "SELECT * FROM Win32_Process WHERE Name='LogonUI.exe'" -ErrorAction Stop
            if($null -eq $LogonUIPresent){ $LogonUIResponse = $false }
            else{ $LogonUIResponse = $true }
        }
        catch{
            $LogonUIResponse = "ERROR"
        }
    #endregion

    #region PSObject
        $WindowsComputerStateObj = [PSCustomObject]@{
            LoggedOn = $UserPresent
            UserData = $UserData
            Locked = $LogonUIResponse
        }
    #endregion

    #region Response
        if($ReturnType -eq "LoggedOn"){ $WindowsComputerStateObj.LoggedOn }
        elseif($ReturnType -eq "Locked"){ $WindowsComputerStateObj.Locked }
        elseif($ReturnType -eq "All"){ $WindowsComputerStateObj }
    #endregion
}
