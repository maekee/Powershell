 Import-Module SMLets

#$smdefaultcomputer = "<Your SCSM Management Server>"

Function Get-RAReviewers{
    [CmdletBinding()]
    param ([Parameter(Mandatory=$true, Position=0)][string]$ReviewActivityID)

    try{
        $RAClass = Get-SCSMClass -Name System.WorkItem.Activity.ReviewActivity$ -ErrorAction Stop
        $ReviewerRelationship = Get-SCSMRelationshipClass -Name System.ReviewActivityHasReviewer$ -ErrorAction Stop
        $ReviewerIsUser = Get-SCSMRelationshipClass -Name System.ReviewerIsUser$ -ErrorAction Stop
    }
    catch{ Write-Error "Error occurred while getting RA Classes and relationships. Exception: $($_.Exception.Message)" }

    try{ $RAObj = Get-SCSMObject -Class $RAClass -Filter "ID = $ReviewActivityID" -ErrorAction Stop }
    catch{ Write-Error "Error occurred while getting $ReviewActivityID. Exception: $($_.Exception.Message)" }

    if($RAObj -ne $null){
        try{ $RelatedReviewObj = Get-SCSMRelatedObject -SMObject $RAObj -Relationship $ReviewerRelationship -ErrorAction Stop }
        catch{ Write-Error "Error occurred while getting review relationships for RA $ReviewActivityID. Exception: $($_.Exception.Message)" }
    
        if($RelatedReviewObj.Count -gt 0){
            
            [System.Collections.ArrayList]$ReviewersReturned = @()

            ForEach ($Reviewer in $RelatedReviewObj){
                try{
                    $ReviewerUser = Get-SCSMRelatedObject -SMObject $Reviewer -Relationship $ReviewerIsUser -ErrorAction Stop
                    $ReviewersReturned.Add($ReviewerUser) | Out-Null
                }
                catch{ Write-Warning "Error occurred while getting reviewer user (ReviewerClass:ReviewerId $($Reviewer.FullName). Exception: $($_.Exception.Message)" }
                #Write-Host "User:"$User.DisplayName - "Username:"$User.UserName
            }

            #Return Reviewers as Users
            if($ReviewersReturned.Count -ne 0){ $ReviewersReturned }
        }
        else{
            Write-Verbose "No Reviewers found on $($RAObj.Id) ($($RAObj.Title))"
            $null
        }
    }
    else{ Write-Verbose "$ReviewActivityID not found in Service Manager" }

} 
