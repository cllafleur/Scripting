#Requires -version 3

Import-Module "$PSScriptRoot\Automation.Reflection.dll"

function Invoke-DiagnosticComponent{
    [CmdLetBinding(DefaultparameterSetName="Urls")]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeLine=$true)]
        [uri[]]$Urls,
        [Parameter(Mandatory=$false)]
        [string]$ComputerNameOrIp=$null
    )

    if ($input -ne $nothing){
        $Urls = $input
    }

    $namespaces = @{"s"="http://schemas.xmlsoap.org/soap/envelope/";"a"="http://schemas.datacontract.org/2004/07/Vcf.EntLib.Diagnosti.cs";"d"="http://tempuri.org/";"i"="http://www.w3.org/2001/XMLSchema-instance"}
	Write-Progress -Activity "Testing" -PercentComplete 0
	$cpt = 0
	foreach ($url in $Urls) {
		$targetUri = $url.ToString() + "Diagnostic.svc"
		$cpt++
		Write-Progress -Activity "Testing" -Status "$targetUri" -PercentComplete ($cpt/$Urls.Length * 100)
		Write-Output "-> Url testing : $targetUri"
		 
		try {
            $newTargetUri = $targetUri
            $headers = @{"SOAPAction"='"http://tempuri.org/IDiagnosticProbeService/GetDiagnostic"';"Content-Type"="text/xml; charset=utf-8"}
            if ($ComputerNameOrIp -ne "") {
                $builtUri = BuildUriForSpecificServer $ComputerNameOrIp $targetUri
                $newTargetUri = $builtUri["Uri"]
                $headers += $builtUri["Headers"]
            }

			$response = Invoke-WebRequest $newTargetUri -TimeoutSec 300 -Method Post -Headers $headers -Body '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body><GetDiagnostic xmlns="http://tempuri.org/"/></s:Body></s:Envelope>'
			[xml]$xml=$response.Content
			$node=Select-Xml -XPath "/s:Envelope/s:Body/d:GetDiagnosticResponse" -xml $xml -Namespace $namespaces
			Write-Output ($node.Node.InnerText -split '\n' | ? { $_.trim() -ne ""})
		}
		catch {
			$exc = $_
			[xml]$xml=$exc.ErrorDetails
			if ($xml -ne $null) {
				$node = Select-Xml -XPath "/s:Envelope/s:Body/s:Fault/faultstring" -xml $xml -Namespace $namespaces
				Write-Output "-- $($node.Node.InnerText | ? { $_.trim() -ne """"})"
			}
			else {
				Write-Error $exc
			}
		}
		Write-Output "<- Url tested : $targetUri"
	}
}

function BuildUriForSpecificServer {
    param($computerName, [uri]$Uri)

    $newUri = $Uri -replace $Uri.Host, $computerName
    $hostHeader = @{"Host"=$uri.Host}

    return @{"Uri"="$newUri";"Headers"=$hostHeader}
}

function Out-DiagHighlighted {
	[CmdLetBinding(DefaultParameterSetName="content")]
	param([Parameter(Mandatory=$true,ValueFromPipeLine=$true)]$content)

	process {
		foreach ($line in $content){
			if ($content -match "^OK"){
				Write-Host -ForegroundColor Green $line
			}
			elseif ($content -match "^KO") {
				Write-Host -ForegroundColor Red $line
			}
			else {
				Write-Host -ForegroundColor Yellow $line
			}
		}
	}
}

function Install-DiagnosticsComponent {
    [CmdletBinding(DefaultParameterSetname="targetRepositoies")]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]$targetRepositories
    )

    if ($input -ne $nothing){
        $targetRepositories = $input
    }

    DeployDiagnosticsComponent 'install' $targetRepositories
}

function Uninstall-DiagnosticsComponent {
    [CmdletBinding(DefaultParameterSetname="targetRepositoies")]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]$targetRepositories
    )

    if ($input -ne $nothing){
        $targetRepositories = $input
    }

    DeployDiagnosticsComponent 'uninstall' $targetRepositories
}

function DeployDiagnosticsComponent {
    param(
        $command,
        $targetRepositories
    )

    $targetConfigFilename = "web.config"
    $installConfigTransformFile = "web.config.install.xdt"
    $uninstallConfigTransformFile = "web.config.uninstall.xdt"
    $binaries = "$PSScriptRoot"
   
    foreach ($path in $targetRepositories) {

        if (-not (Test-Path "$path")) { Write-Warning "Folder not found : $path" ; continue }
        $folder = (Resolve-Path "$path")

        $dotnetVersion = Get-DotnetFolderVersion $folder

        if ($dotnetVersion -eq $null) { continue }

        switch($command) {
            "install" { InstallComponent  (Join-Path "$PSScriptRoot" $dotnetVersion) (Resolve-Path "$path").ProviderPath }
            "uninstall" { UninstallComponent  (Join-Path "$PSScriptRoot" $dotnetVersion) (Resolve-Path "$path").ProviderPath }
            default { Write-Error "Unknown command ""$command"""  }
        }
        Write-Output ""
    }
}

function TransformConfigFile {
    param($configFile, $xdtFile)

    $oldFile = $configFile + ".old"
    $newFile = $configFile + ".new"

    Write-Output "Creating config backup $oldFile"
    Copy-Item -Force "$configFile" "$oldFile"

    Write-Output "Transforming config file to $newFile"
    & "$binaries\ctt.exe" s:"$configFile" t:"$xdtFile" d:"$newFile"

    Write-Output "Updating config file $configFile"
    Move-Item -Force "$newFile" "$configFile"
}

function CopyFolderContent {
    param($sourceFolder, $targetFolder)

    Write-Output "Copying files from $sourceFolder"
    Push-Location "$sourceFolder"
    foreach ($file in ls) {
        Copy-Item -Force "$file" "$targetFolder"
    }
    Pop-Location
}

function DeleteFolderContent {
    param($sourceFolder, $targetFolder)

    Write-Output "Deleting files from $sourceFolder"
    Push-Location "$sourceFolder"
    foreach ($file in ls) {
           $filePath = Join-Path "$targetFolder" "$file"
        Remove-Item -Force "$filePath"
    }
    Pop-Location
}

function InstallComponent {
    param($sourceRepository, $targetRepository)

    TransformConfigFile (Join-Path "$targetRepository" $targetConfigFilename) (Join-Path "$sourceRepository" $installConfigTransformFile)
    CopyFolderContent (Join-Path "$sourceRepository" "content") "$targetRepository"
    CopyFolderContent (Join-Path "$sourceRepository" "bin") (Join-Path "$targetRepository" "bin")
}

function UninstallComponent {
    param($sourceRepository, $targetRepository)

    TransformConfigFile (Join-Path "$targetRepository" $targetConfigFilename) (Join-Path "$sourceRepository" $uninstallConfigTransformFile)
    DeleteFolderContent (Join-Path "$sourceRepository" "content") "$targetRepository"
    DeleteFolderContent (Join-Path "$sourceRepository" "bin") (Join-Path "$targetRepository" "bin")
}

function Get-AppClrVersion() {
    param($targetFolder)

    (ls -Recurse "$targetFolder" *.dll | % { $filename = $_.FullName
        $version = Get-CLRVersion "$filename"
        $version.SubString(1, 1)
    } | measure -Maximum).Maximum
}

function Get-DotnetFolderVersion {
    param($targetFolder)

    switch (Get-AppClrVersion "$targetFolder") {
            2 {
                write-host -ForegroundColor Green "net35 detected. $path"
                $dotnetVersion = "net35" }
            4 {
                write-host -ForegroundColor Green "net40 detected. $path"
                $dotnetVersion = "net40" }
            default { 
                $dotnetVersion = $null
                Write-Warning "dotnet version undetermined. Skipping : $path"
            }
        }

    return $dotnetVersion
}

$appRepository = "$PSScriptRoot\apps"

function GetAvailableApps {
    $availableApps = ls $appRepository|ls | %{GetAppName $_.FullName}
    $appsTypeTest = BuildIndex
    $availableApps  
}

function BuildIndex{
    $index = @{}
    foreach ($item in (ls $appRepository | ls)) {
        $key = GetAppName $item.FullName
        [string[]]$value = (ls $item.FullName | %{$_.Name})
        $index.Add($key, $value)
    }
    return $index
}

function Install-DiagnosticFiles {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]$targetFolders
    )

    begin {
       
    }
    process {
        foreach ($targetFolder in $targetFolders){
            $appName = GetAppName $targetFolder
            if (Test-AvailableApp $targetFolder) {
                $dotnet = Get-DotnetFolderVersion $targetFolder
                foreach ($item in $appsTypeTest[$appName]) {
                    
                    Copy-Item -force "$appRepository\$appName\$item" "$targetFolder"
                    write-host "Copied file $appName\$item to $targetFolder"
                    Copy-Item -force "$PSScriptRoot\$dotnet\$item\*.dll" "$targetFolder\bin"
                    write-host "Copied file $dotnet\$item\*.dll to $targetFolder\bin"
                }
            }
            else {
                Write-Warning "Unknown apps $($targetFolder.fullname)"
            }
        }
    }
    end {}
}

function Test-AvailableApp{
    param($targetFolder)

    $appName = GetAppName $targetFolder
    return $availableApps -contains $appName
}

function GetAppName{
    param($appPath)

    $item = $appPath

    "$(Split-Path "$item" -Parent|Split-Path -Leaf)\$(Split-Path "$item" -Leaf)"
}

$appsTypeTest = BuildIndex
$availableApps = GetAvailableApps

$importedFunc = {
    function global:GetBindingUrlFromCollection {
        param($collection)

        $collection | %{
            if ("http","https" -contains $_.Protocol) {
                [string[]] $tab = $_.BindingInformation -split ":"
                $currentUrl = $_.Protocol + "://"
                if ($tab[2] -like "") {
                    $currentUrl += "localhost"
                }
                else {
                    $currentUrl += $tab[2]
                }
                if ("80","443" -notcontains $tab[1]) {
                    $currentUrl += ":" + $tab[1]
                }
                write-output ([uri]$currentUrl).ToString()
            }
        }
    }
}


function GetSiteNameWithHostname {
    param($computerName)

    $sitenames = Invoke-Command $computerName -ArgumentList $importedFunc -scriptblock {
        param($initScript)
        import-module webadministration

        Invoke-Command -scriptblock ([scriptblock]::Create($initScript))

        $siteNames = @{}

        Get-Website | %{ $sitename = $_.name;
                $siteUrls = GetBindingUrlFromCollection $_.bindings.collection
                foreach ($url in $siteUrls) {
                    $sitenames[$url] += [array]$sitename
                }
            }
            $sitenames
        #}
    }
    $sitenames
}

function SetAuthenticationOnSite {
    param($computerName, $siteNames)

    $ret = Invoke-Command $computerName -ArgumentList $siteNames, -ScriptBlock {
        param([string[]]$siteNames)
        import-module webadministration

        foreach ($siteName in $siteNames) {
            if($siteName -like ""){
                continue
            }
            Write-Host "Set anonymous auth on location $siteName/Diagnostic.svc"
            Start-Process -FilePath "C:\windows\system32\inetsrv\appcmd.exe" -ArgumentList "set","config","$siteName/Diagnostic.svc","-section:system.webServer/security/authentication/anonymousAuthentication","-enabled:true","-commit:apphost" -Wait
            Write-Host "Set anonymous auth on location $siteName/Availability.svc"
            Start-Process -FilePath "C:\windows\system32\inetsrv\appcmd.exe" -ArgumentList "set","config","$siteName/Availability.svc","-section:system.webServer/security/authentication/anonymousAuthentication","-enabled:true","-commit:apphost" -Wait

            #avec le module webadministration
            # Set-WebConfigurationProperty -filter /system.webServer/security/authentication/anonymousAuthentication -name enabled -value true -location "$siteName/Availability.svc" -Verbose
        }
    }
    $ret
}

function Set-AuthenticationOnDiagFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $computerName,
        [Parameter(Mandatory=$true, ValueFromPipeLine=$true)]
        $urls
    )
    begin {
        $computerSiteNames = GetSiteNameWithHostname $computerName
    }
    process {
        $siteNames = @()
        foreach ($url in $urls) {
            $sitenames += $computerSiteNames[$url]
        }
        SetAuthenticationOnSite $computerName ($siteNames | sort -Unique)
    }
}


Export-ModuleMember -Function *-*