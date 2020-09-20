## Here are a few functions i use to get and software updates available in Software Center on servers.
## Added function to get Restart state, in case software updates are ready and waiting for reboot.

## Remember to run these as admin

Function Get-SoftwareCenterUpdates{
    [CmdletBinding()]
    param(
        [String][Parameter(Mandatory=$false, Position=0)]$ComputerName = $env:COMPUTERNAME
    )

    try{
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $ComputerName = $args[0]
            Get-WmiObject -Namespace "root\ccm\clientSDK" -Class CCM_SoftwareUpdate -ComputerName $ComputerName -ErrorAction Stop
        } -ArgumentList $ComputerName | Select Name,@{name='State';expression={
            if($_.EvaluationState -eq 0){"None"}
            elseif($_.EvaluationState -eq 1){"Available"}
            elseif($_.EvaluationState -eq 2){"Submitted"}
            elseif($_.EvaluationState -eq 3){"Detecting"}
            elseif($_.EvaluationState -eq 4){"PreDownload"}
            elseif($_.EvaluationState -eq 5){"Downloading"}
            elseif($_.EvaluationState -eq 6){"WaitInstall"}
            elseif($_.EvaluationState -eq 7){"Installing"}
            elseif($_.EvaluationState -eq 8){"PendingSoftReboot"}
            elseif($_.EvaluationState -eq 9){"PendingHardReboot"}
            elseif($_.EvaluationState -eq 10){"WaitReboot"}
            elseif($_.EvaluationState -eq 11){"StateVerifying"}
            elseif($_.EvaluationState -eq 12){"InstallComplete"}
            elseif($_.EvaluationState -eq 13){"Error"}
            elseif($_.EvaluationState -eq 14){"WaitServiceWindow"}
            elseif($_.EvaluationState -eq 15){"WaitUserLogon"}
            elseif($_.EvaluationState -eq 16){"WaitUserLogoff"}
            elseif($_.EvaluationState -eq 17){"WaitJobUserLogon"}
            elseif($_.EvaluationState -eq 18){"WaitUserReconnect"}
            elseif($_.EvaluationState -eq 19){"PendingUserLogoff"}
            elseif($_.EvaluationState -eq 20){"PendingUpdate"}
            elseif($_.EvaluationState -eq 21){"WaitingReply"}
            elseif($_.EvaluationState -eq 22){"WaitPresModeOff"}
            elseif($_.EvaluationState -eq 23){"WaitForOrchestration"}
        }},Publisher,ArticleID,Deadline,Description,PSComputerName
    }
    catch{
        Write-Warning "Error occurred while getting installation of Updates in Software Center. Exception: $($_.Exception.Message)"
    }
}
Function Install-SoftwareCenterUpdates{
    [CmdletBinding()]
    param(
        [String][Parameter(Mandatory=$false, Position=0)]$ComputerName = $env:COMPUTERNAME
    )

    try{
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $ComputerName = $args[0]
            $UpdatesAvailable = Get-WmiObject -Namespace "root\ccm\clientSDK" -Class CCM_SoftwareUpdate -Filter "EvaluationState = 0 or EvaluationState = 1" -ComputerName $ComputerName -ErrorAction Stop
            Invoke-WmiMethod -Class CCM_SoftwareUpdatesManager -Name InstallUpdates -ArgumentList (,$UpdatesAvailable) -Namespace root\ccm\clientsdk -ComputerName $ComputerName -ErrorAction Stop | Out-Null
        } -ArgumentList $ComputerName
        Write-Verbose "Successfully started installation of all available software updates on $ComputerName"
    }
    catch{
        Write-Warning "Error occurred while starting installation of Updates in Software Center. Exception: $($_.Exception.Message)"
    }
}
Function Get-RestartState{
    param($ComputerName)

    $RestartObj = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        $ComputerName = $args[0]
        Invoke-WmiMethod -ComputerName $ComputerName -Namespace "ROOT\ccm\ClientSDK" -Class CCM_ClientUtilities -Name DetermineIfRebootPending
    } -ArgumentList $ComputerName
        
    if($RestartObj){
        $RestartObj.RebootPending
    }
}
