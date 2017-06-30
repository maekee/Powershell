 Function Get-SCSMSystemDomainUserEmail{
    param($UserEnterpriseManagementObject)

    if($UserEnterpriseManagementObject -ne $null){

        if($UserEnterpriseManagementObject.GetType().FullName -eq "Microsoft.EnterpriseManagement.Common.EnterpriseManagementObject"){

            try{ $UserHasPreferenceClass = Get-SCSMRelationshipClass -Name System.UserHasPreference$ -ErrorAction Stop }
            catch{ Write-Error "Error occurred while getting System.UserHasPreference relationship. Exception: $($_.Exception.Message)" }

            if($null -ne $UserHasPreferenceClass){
                try{ $UserSMTPNotifications = @(Get-SCSMRelatedObject -SMObject $UserEnterpriseManagementObject -Relationship $UserHasPreferenceClass -ErrorAction Stop | Where {$_.ChannelName -eq "SMTP"}) }
                catch{ Write-Error "Error occurred while getting users SMTP notifications channels. Exception: $($_.Exception.Message)"  }
            }

            if($UserSMTPNotifications.Count -eq 1){
                $UserSMTPNotifications[0].TargetAddress
            }
            elseif($UserSMTPNotifications.Count -gt 1){
                Write-Verbose "$($UserSMTPNotifications.Count) SMTP Notification targets found ($($UserSMTPNotifications.TargetAddress -join ",")), returning first 1"
                $UserSMTPNotifications[0].TargetAddress
            }
            elseif($UserSMTPNotifications.Count -eq 0){
                Write-Verbose "No SMTP nofication address found for user $($UserEnterpriseManagementObject.UPN), nothing returned"
                $null
            }
        }
        else{ Write-Verbose "Parameter UserEnterpriseManagementObject is not of type Microsoft.EnterpriseManagement.Common.EnterpriseManagementObject";$null }
    }
    else{ Write-Verbose "Parameter UserEnterpriseManagementObject is NULL";$null }
} 
