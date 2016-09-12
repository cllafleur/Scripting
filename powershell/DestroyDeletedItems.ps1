#$tab = tf dir /recursive /folders /collection:"http://srvmigtfs10at:8080/tfs/Tfs2008PT" "$/Iris v2" | ? { $_ -match "\$[/\w\d\.\s]+/generated"} | %{ ($_ | select-string -pattern '\$[/\w\d\.\s]+').Matches.Value }
#$tab | %{ $current = $_ ; tf destroy /startcleanup /collection:"http://srvmigtfs10at:8080/tfs/Tfs2008PT" "$current" }

param($tfsPath = "$/Iris v2")
$tfsCollection = "http://srvmigtfs10at:8080/tfs/Tfs2008PT"

if ($tfspath -eq $nothing) {
    throw "A TfsPath is required. ex : '$/VHA'"
}

function Destroy-DeletedChildren() {
    param($currentTfsPath, $currentTfsCollection)

    $itemToDestroy = (tf dir /deleted /Collection:"$currentTfsCollection" $currentTfsPath | ? { $_ -match "\$.+;X\d+" } | %{ "$currentTfsPath/" + ($_ | Select-String  -pattern '(?!\$).+;X\d+').matches.Value })

    $itemToDestroy | % {
        $currentTfsItem = $_
        Write-host "Destroying $currentTfsItem" -ForegroundColor Red

        tf destroy /startcleanup /Collection:"$currentTfsCollection" "$currentTfsItem" > $null
    }
}

function Search-DeletedChildren() {
    param($currentTfsPath, $currentTfsCollection, $progressIndex)

    Destroy-DeletedChildren $currentTfsPath $tfsCollection
    $items = (tf dir /folders /Collection:"$currentTfsCollection" "$currentTfsPath" | ? { $_ -match "\$[^/:]" } | % { "$currentTfsPath/" + ($_ | Select-String  -pattern '(?!\$).+').matches.Value })
    $cpt = 0
    $items | % {
        $currentItem = $_
        $cpt += 1
        if ($progressIndex -lt 5) {
            Write-Progress -Id $progressIndex -PercentComplete ($cpt *100 / $items.Length) -Activity "Browsing $currentItem" -ParentId ($progressIndex - 1)
            $script:activity = "Browsing $currentItem"
            $script:progress = ($cpt *100 / $items.Length)
            $script:progressParentId = ($progressIndex - 1)
        }
        else {
            write-progress -id 4 -Activity $script:activity -Status "Browsing $currentItem" -PercentComplete $script:progress -ParentId $script:progressParentId
           # Write-Host "Browsing $currentItem"
        }
        Search-DeletedChildren $currentItem $currentTfsCollection ($progressIndex + 1)
    }
    if ($progressIndex -lt 5) {
        Write-Progress -id $progressIndex -activity "Browsing $currentItem" -Completed
    }
}

Search-DeletedChildren $tfsPath $tfsCollection 1


