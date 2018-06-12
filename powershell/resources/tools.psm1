Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Function Remove-ResourceKeys() {
    <#
    .SYNOPSIS
        Remove resource keys from resx files
    .PARAMETER resxKeys
        List resource keys to remove
    .PARAMETER resourceFiles
        List of files to look for keys to be removed.
    .DESCRIPTION
        An example that describe how to use it.

        PS> Remove-ResourceKeys -resxKeys ("key1", "key2") -resourceFiles (ls -Recurse -include GlobalResources_BO*.resx)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string[]]$resxKeys,
        [Parameter(Mandatory=$True)]
        [string[]]$resourceFiles
    )

    $matchingResourceRegex = "(?sm)\s*<data name=""($($resxKeys -join "|"))"".*?</data>"
    $resourceFiles | ForEach-Object {
        $filename = "$_"
        $contentFile = (get-content $filename -raw -Encoding UTF8)
        if ($contentFile -match $matchingResourceRegex) {
            $contentFile | Where-Object { $_ -replace $matchingResourceRegex, "" | Set-Content -path $filename -Encoding UTF8 -NoNewline }
            Write-Information "Updated file -> $($filename)"
        }
    }
}

function Remove-RemnantKeys {
    <#
    .SYNOPSIS
        Remove the remnant keys (existing keys not in the neutral language) from all resx files.
    #>
    Write-Host "Getting resx files"
    $groups = Get-GroupedResxFiles
    $count = 0
    $groups.Keys | Foreach-Object {
        $neutralFile = $_
        $neutralKeys = Get-ResourceKeysFrom $neutralFile
        Write-Host "Working on $neutralFile"

        $specificFiles = $groups[$neutralFile]
        $specificFiles | Foreach-Object {
            $file = $_
            $keys = Get-ResourceKeysFrom $file
            $remnants = @() + ($keys | Where-Object { $neutralKeys -notcontains $_ })
            if($remnants -ne $null) {
                Remove-ResourceKeys $remnants $file
                $count += $remnants.Count
            }
        }
    }
    Write-Host "Removed $count remnant key(s)"
}

Function Update-NeutralLanguage {
    <#
    .SYNOPSIS
        Replace all resource values of the neutral language by en-GB language ones.
    .DESCRIPTION
        An example that describe how to use it.

        PS> Update-NeutralLanguage
    #>
    $files = Get-ResXFiles
    $cpt = 0
    foreach ($file in $files) {
        $referenceFile = (Convert-FilenameToTranslatedFilename $file)
        Write-Progress -Activity "Refreshing neutral language" -status "$($file.name)" -percentcomplete (100*$cpt/$files.length)
        if (Test-Path $referenceFile) {
            Update-FileResourcesWith $file $referenceFile
        }
        $cpt++
    }
}

function Update-FileResourcesWith {
    param($fileToUpdate, $referenceFile)

    $keysToAdd = Get-ResourceKeysFrom $fileToUpdate
    $fallbackLanguage = Get-ResourcesFrom $fileToUpdate
    $translatedResources = Get-ResourcesFrom $referenceFile
    $commentOfTheResources = Get-ResourceCommentsFrom $fileToUpdate
    $resourcesToInsert = Get-ResourcesToInsert $keysToAdd $translatedResources $fallbackLanguage $commentOfTheResources
    $newFileContent = Get-UpdatedNeutralLanguageFile $fileToUpdate $resourcesToInsert
    $newFileContent | Set-Content -Encoding UTF8 $fileToUpdate
}

function Get-GroupedResxFiles {
    <#
    .SYNOPSIS
        Gets the resx files, grouped by neutral language.
        Returns a hashtable where keys are neutral language files and values are arrays of specific language files.
    #>
    $files = Get-ChildItem .\Sources\Resources -Recurse -Include *.resx | sort
    $groups = @{}

    $files | Foreach-Object {
        $file = $_.FullName
        if ($file -match '(.*)\.\w{2}-\w{2}\.resx') {
            $neutralFileName = $matches[1] + '.resx'
            if(-not $groups.ContainsKey($neutralFileName)) { $groups[$neutralFileName] = @() }
            $groups[$neutralFileName] += $file
        } else {
            if(-not $groups.ContainsKey($file)) { $groups[$file] = @() }
        }
    }

    return $groups
}

function Get-ResXFiles {
    $matchingResxFileNameRegex = "(?'blop2'\w*(?<!.\w{2}-\w{2}).resx)"
    Get-ChildItem .\Sources\Resources -Recurse -Include *.resx | ? { $_.Name -match $matchingResxFileNameRegex }
}

function Convert-FilenameToTranslatedFilename  {
    param($filename)

    $parent = split-Path $filename -parent
    $base = $filename.BaseName
    $extension = $filename.Extension
    join-path $parent ("$base.en-GB$extension") 
}

function Get-UpdatedNeutralLanguageFile {
    param($filename, $resourcesToInsert)

    $regexToRemoveData = "(?smx)(?>
    (?<cmt>(?:(?<open><!--).*?)+(?<-open>-->)*(?(open)(?!)))
    |
    (?<data>\s*<data\s+name=.*?</data>))"
    $regexToRemoveFileTail = "(?sm)\s*</root>\s*"
    $content = (Get-Content $filename -Encoding UTF8 -Raw)
    $content = $content -replace $regexToRemoveData, "`${cmt}"
    $content = $content -replace $regexToRemoveFileTail, ""
    $content += $resourcesToInsert
    $content += "`r`n</root>"
    $content
}

function Remove-XmlCommentSection {
    param(
        [parameter(ValueFromPipeline)]
        $content
    )

    $matchingXmlCommentRegex = "(?sm)\s*\<!--.*?--\>"
    $content -replace $matchingXmlCommentRegex, ""
}

function Get-ResourcesToInsert () {
    param($keysToBeInserted, $languageToAdd, $fallbackLanguage, $resourceComments)

    $output = ""
    $keysToBeInserted | Foreach-Object {
        $key = $_
        if ($languageToAdd.ContainsKey($key)) {
            $dataElement = $languageToAdd[$key]
            if ($resourceComments.ContainsKey($key)){
                $dataElement = Get-ResourceDataWithCommentInserted $dataElement $resourceComments[$key]
            }
            $output += $dataElement
        }
        else {
            $output += $fallbackLanguage[$key]
        }
    }
    $output
}

function Get-ResourceDataWithCommentInserted {
    param($resourceData, $commentToInsert)

    $matchingCommentRegex = "(?sm)\s*<comment>.*?</comment>"
    $matchingTailRegex = "(?sm)(?<tail>\s*</data>\s*)"
    $cleanedResourceData = $resourceData -replace $matchingCommentRegex, ""
    $cleanedResourceData -match $matchingTailRegex | Out-Null
    $stringTail = $Matches["tail"]
    $output = $cleanedResourceData -replace $matchingTailRegex, ""
    $output += $commentToInsert
    $output += $stringTail
    $output
}

Function Get-ResourceKeysFrom () {
    param($filename)

    $matchingString = "(?sm)\s*<data name=""(?<name>.+?)"".*?</data>"
    [string[]]$keys = (Get-Content $filename -Encoding UTF8 -Raw)| Remove-XmlCommentSection | select-string -Pattern $matchingString -AllMatches | Foreach-Object { $_.Matches } | Foreach-Object { $_.Groups["name"].Value }
    $keys
}

function Get-ResourceCommentsFrom  {
    param($filename)
    
    # This regex is really slow, it should be optimazed in the future.
    $matchingString = '(?sm)<data name="(?<name>[\w\d_-]+)"(\s+[\w:\d_-]+="[\w\d_-]+")*>\s*(?><(?<prev>[\w\d_-]+)>.*?</\k<prev>>)*(?<cmt>\s*<comment>.+?</comment>)\s*</data>'
    $commentHashtable = @{}
    (Get-Content $filename -Encoding UTF8 -Raw) | Remove-XmlCommentSection | select-string -Pattern $matchingString -AllMatches | Foreach-Object { $_.Matches } | Foreach-Object {
        $match = $_
        $key = $match.Groups["name"].Value
        if ($match.Groups["cmt"].Success) {
            if ($commentHashtable.ContainsKey($key)) {
                $commentHashtable[$key] = $match.Groups["cmt"].Value
            }
            else {
                $commentHashtable.Add($key, $match.Groups["cmt"].Value)
            }
        }
    }
    $commentHashtable
}

Function Get-ResourcesFrom () {
    param($filename)

    $matchingString = "(?sm)\s*<data name=""(?<name>.+?)"".*?</data>"
    $keyHashtable = @{}
    (Get-Content $filename -Encoding UTF8 -Raw) | Remove-XmlCommentSection | select-string -Pattern $matchingString -AllMatches | Foreach-Object { $_.Matches } | Foreach-Object {
        $match = $_
        $key = $match.Groups["name"].Value
        if ($keyHashtable.ContainsKey($key)) {
            $keyHashtable[$key] = $match.Groups[0].Value
        }
        else {
            $keyHashtable.Add($key, $match.Groups[0].Value)
        }
    }
    $keyHashtable
}

#export-modulemember -function Update-NeutralLanguage
