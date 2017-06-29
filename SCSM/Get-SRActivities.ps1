 Import-Module SMLets

#$smdefaultcomputer = "<Your SCSM Management Server>"

Function Get-SRActivities{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$ServiceRequestID,
        [switch]$OnlyReviewActivities
    )

    try{
        $ServiceRequestClass = Get-SCSMClass -Name System.WorkItem.ServiceRequest$ -ErrorAction Stop
        $ReviewActivityClass = Get-SCSMClass -Name System.WorkItem.Activity.ReviewActivity$ -ErrorAction Stop
        $WorkItemRelatesToWorkItemRelClass = Get-SCSMRelationshipClass -Name System.WorkItemRelatesToWorkItem$ -ErrorAction Stop
        $WorkItemContainsActivityRelClass = Get-SCSMRelationshipClass -Name System.WorkItemContainsActivity$ -ErrorAction Stop
    }
    catch{ Write-Error "Error occurred while getting SR/RA classes and relationships. Exception: $($_.Exception.Message)" }

    try{ $SRObj = Get-SCSMObject -Class $ServiceRequestClass -Filter "ID -eq $ServiceRequestID" -ErrorAction Stop }
    catch{ Write-Error "Error occurred while getting $ServiceRequestID. Exception: $($_.Exception.Message)" }

    if($SRObj -ne $null){
        try{ $WorkItemActivityRelationShips = @(Get-SCSMRelatedObject -Relationship $WorkItemContainsActivityRelClass -SMObject $SRObj) }
        catch{ Write-Error "Error occurred while getting related activities relationships for $($SRObj.Id). Exception: $($_.Exception.Message)" }

        if($WorkItemActivityRelationShips.Count -gt 0){
            if($OnlyReviewActivities){
                $WorkItemActivityRelationShips = @($WorkItemActivityRelationShips | Where {$_.ClassName -eq "System.WorkItem.Activity.ReviewActivity"})
                if($WorkItemActivityRelationShips.Count -gt 0){
                    $WorkItemActivityRelationShips
                }
                else{
                    Write-Verbose "No Related Review activities found on $($SRObj.Id)"
                    $null
                }
            }
            else{ $WorkItemActivityRelationShips }
        }
        else{
            Write-Verbose "No Related activities found on $($SRObj.Id)"
            $null
        }
    }
    else{ Write-Verbose "$ServiceRequestID not found in Service Manager" }
} 
