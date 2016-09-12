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

$teamProjectCollection = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection("http://srvdtfs2010at:8080/tfs/Target/")

$ws = $teamProjectCollection.GetService([type]"Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore")

$query = "select [Id], [Iteration Path], [Title] FROM workitems where [Work Item Type] = 'Release' or [Work Item Type] = 'Sprint' or [Work Item Type] = 'Team Sprint'"

$wis=$ws.Query($query)

$wis | %{
    $wi = $_
    Write-Output $wi.IterationPath
    $linkToRemove = @()
    $linkToRemove += ($wi.Links)
    $linkToRemove | % { $wi.links.Remove($_) }
    $wi.Save()
}
