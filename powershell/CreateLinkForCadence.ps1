param(
  $projectCollectionUrl = "http://srvtfs10at01:8080/tfs/DsiDev/",
  $projectName = "EtudeDePrix"  
)


$asm = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Client")
if ($asm -ne $nothing) {
    write-output "Microsoft.TeamFoundation.Client loaded."
}

$asm = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation")
if ($asm -ne $nothing) {
    write-output "Microsoft.TeamFoundation loaded."
}

$asm = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.WorkItemTracking.Client")
if ($asm -ne $nothing) {
    write-output "Microsoft.TeamFoundation.WorkItemTracking.Client loaded."
}

$teamProjectCollection = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($projectCollectionUrl)
#$css = $teamProjectCollection.GetService([type]"Microsoft.TeamFoundation.Server.ICommonStructureService3")
$ws = $teamProjectCollection.GetService([type]"Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore")



if ($ws -eq $nothing) {
    Write-Output "no store"
}

function GetChildrenWorkItems() {
    param($iterationPathBase, $workItemType)

    $childrenQuery = "select [Id], [Title] from workitems where [Team Project] = '$projectName' and [Iteration Path] Under '$iterationPathBase' and [Work Item Type] = '$workItemType'"
    $ws.Query($childrenQuery)
}

function LinkWorkItems() {
    param($parentWorkItem, $childWorkItem, $linkTypeName)

    $linkType = $ws.WorkItemLinkTypes[$linkTypeName]
    $link = New-Object Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemLink($linkType.ForwardEnd, $childWorkItem.Id)
    $parentWorkItem.Links.Add($link) > $null
}

$query = "select [Id], [Iteration Path], [Title] FROM workitems where [Team Project] = '$projectName' and [Work Item Type] = 'Release'"

$wis=$ws.Query($query)
if ($wis -eq $nothing) {
    write-output "No release workItem found."
    return
}

$wis | %{
    $currentRelease = $_
    Write-Output $currentRelease.IterationPath

    GetChildrenWorkItems $currentRelease.IterationPath 'Sprint' | % {
        $currentSprint = $_
        LinkWorkItems $currentRelease $currentSprint "Scrum.ImplementedBy"
        Write-Output $currentSprint.IterationPath

        GetChildrenWorkItems $currentSprint.IterationPath 'Team Sprint' | % {
            $currentTeam = $_
            LinkWorkItems $currentSprint $currentTeam "Scrum.ImplementedBy"
            Write-Output $currentTeam.IterationPath
        }
        $currentSprint.Save()
    }

    $currentRelease.Save()
}