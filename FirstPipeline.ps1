function Get-PolicyAssignmentToProductionGroups {
    param (
        [array] $ArrayOfGroups,
        [string] $TargetGroupId
    )
    write-host "Finding " $TargetGroupId " in " $ArrayOfGroups
    if($ArrayOfGroups -contains $TargetGroupId){
        return $true
    }
    else {
        return $false
    }
}

Function Get-AssignmentTargetObject {
    param ([string] $TargetGroupID)
    $assignmentTarget = @{
        "groupId" = $TargetGroupID
        "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
    }
    return $assignmentTarget
}

#Connect-MgGraph -NoWelcome

#$PoliciesToBeReleased = Get-MgBetaDeviceManagementDeviceConfiguration -filter "contains(description,'Release')"
$PoliciesToBeReleased = Get-MgBetaDeviceManagementConfigurationPolicy -filter "contains(description,'Release')"
$ProdGroups = Get-MgBetaGroup -Filter "startswith(displayName,'Prod')"
$TargetGroupsID = $ProdGroups.ID
#$GroupsToBeAssigned = @()
$PolicyRequiresAssignment = $false
$PolicyAlreadyAssignedToProd = @()
$Count=0


if($PoliciesToBeReleased.count -gt 0)
{
    foreach($Policy in $PoliciesToBeReleased)
    {
        
        $PolicyRequiresAssignment = $false
        $PolicyID = $Policy.Id
        #$Assignments = Get-MgBetaDevicemanagementConfigurationGroupAssignment -DeviceConfigurationID $PolicyID
        $Assignments = Get-MgBetaDevicemanagementConfigurationPolicyAssignment -DeviceManagementConfigurationPolicyId $PolicyID
        write-host $Assignments.Count
        foreach($assignment in $Assignments)
        {
            write-host $Policy.DisplayName " " $assignment.TargetGroupId
            #if(-not($TargetGroups.Id -contains $assignment.TargetGroupId)){write-host "Not Found"}
            If(Get-PolicyAssignmentToProductionGroups -ArrayOfGroups $TargetGroupsID -TargetGroupID $assignment.TargetGroupId) 
            {
                write-host "Doing Nothing"
                $PolicyAlreadyAssignedToProd += $assignment.TargetGroupId
                
            }
            else
            {
                $PolicyRequiresAssignment = $true
            }
        }
        if($PolicyRequiresAssignment)
        {
            foreach($TargetGroup in $TargetGroupsID)
            {
                if((-not(Get-PolicyAssignmentToProductionGroups -ArrayOfGroups $PolicyAlreadyAssignedToProd -TargetGroupId $TargetGroup) -AND ($Count -eq 0)))
                {
                    $TargetObject = Get-AssignmentTargetObject -TargetGroupID $TargetGroup
                    New-MgBetaDeviceManagementDeviceConfigurationAssignment -DeviceConfigurationId $PolicyId -Target $TargetObject
                    write-host "Need to add " $TargetGroup " to " $PolicyID
                    $Count++
                }
            }
        }
        $PolicyAlreadyAssignedToProd.Clear()
    }
}

