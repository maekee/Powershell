#Nice little function:
#1. Identify local administrator name (SID 500)
#2. Change password (25 mixed characters)
#3. Validate that the password was changed
#4. Report back status, and new password (can be disabled if desired)

Function Reset-LocalAdminPwd{
    [CmdletBinding()]
    param( [switch]$NoPwdChange )

    #region Get local administrator
        try{ $AdminName = (Get-WmiObject -Query "Select * From Win32_UserAccount Where LocalAccount = TRUE" -ErrorAction Stop | Where {$_.SID -match "-500$"}) }
        catch{ Write-Warning "Problems fetching the local administrator. Exception: $($_.Exception.Message)" }

        if($null -eq $AdminName){ Write-Warning "Local Administrator not found on $($env:COMPUTERNAME)" }
        else{$AdminName = $AdminName.Name}
    #endregion

    if($AdminName){
        #region Generate new administrator password
            $NewPassword = ([char[]]([char]33,[char]36,[char]37,[char]38,[char]41,[char]45) + ([char[]]([char]97..[char]122)) + ([char[]]([char]65..[char]86)) + 0..9 | sort {Get-Random})[0..25] -join ''
        #endregion

        if(!($NoPwdChange)){
            #region Set new administrator password
                try{
                    #([ADSI]”WinNT://$($env:COMPUTERNAME)/$AdminName,User”).SetPassword($NewPassword)
                    $LocalAdminObj = [ADSI]"WinNT://$($env:COMPUTERNAME)/$AdminName,user"
                    $LocalAdminObj.SetPassword($NewPassword)
                    $LocalAdminObj.SetInfo()
                }
                catch{ Write-Warning "Failed reseting password for $AdminName on computer $($env:COMPUTERNAME). Exception: $($_.Exception.Message)" }
            #endregion
            #region Verify administrator new password
                Add-Type -AssemblyName System.DirectoryServices.AccountManagement 
                $principalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext( [System.DirectoryServices.AccountManagement.ContextType]::Machine,$($env:COMPUTERNAME) )
                $newPwdStatus = $principalContext.ValidateCredentials($AdminName,$NewPassword)
            #endregion
        }
        else{ Write-Verbose "Not changing password for $AdminName on $($env:COMPUTERNAME), because of parameter NoPwdChange" }

        #region return result object
            if($newPwdStatus -ne $true -and $newPwdStatus -ne $false){ $newPwdStatus = $false;$NewPassword = $null }

            [PSCustomObject]@{
                "ComputerName" = $($env:COMPUTERNAME)
                "ChangeStatus" = $newPwdStatus
                "Password" = $NewPassword
            }
        #endregion
    }
}
