

$currentFolder = $PSScriptRoot
Push-Location "$currentFolder"
$probeProjectBaseDirectory = "..\..\Server\Sources"
$nuspecDirectory = "..\..\Nuspecs"

if (Test-Path net35) {Remove-Item -force -Recurse net35}
if (Test-Path net40) {Remove-Item -force -Recurse net40}

# build .net35 components
Write-Host "Build net35 components started"
Push-Location "$probeProjectBaseDirectory\Diagnostics.Probes.net35"
& msbuild /t:clean "Diagnostics.Probes.net35.csproj" > $null
& msbuild /t:Build "Diagnostics.Probes.net35.csproj" > $null
if ($?) {
    write-host -ForegroundColor Green "Build net35 components succeded"
}
else {
    Write-host -ForegroundColor Red "Build net35 components failed"
}
Pop-Location

Write-Host "Copying net35 components files"
try {
    New-Item -force ".\net35\content" -type directory > $null
    New-Item -force ".\net35\bin" -type directory > $null
    New-Item -force ".\net35\DbTableTestDescription.json" -type directory > $null
    New-Item -force ".\net35\RsReportTestDescription.json" -type directory > $null
    Copy-Item -Force "$nuspecDirectory\content\net35\*" ".\net35\"
    Copy-Item -Force "$probeProjectBaseDirectory\Diagnostics.Probes.net35\*.svc" ".\net35\content\"
    Copy-Item -Force "..\..\CompileOutput\Debug\net35\*.dll" ".\net35\bin\"
    Move-Item -Force ".\net35\bin\Vcf.EntLib.Diagnostics.SelfTests.DbTables.dll" ".\net35\DbTableTestDescription.json" 
    Move-Item -Force ".\net35\bin\Vcf.EntLib.Diagnostics.SelfTests.DataAccessRSReports.dll" ".\net35\RsReportTestDescription.json" 
    Write-Host -ForegroundColor Green "Copy succeded"
}
catch {
    write-host -ForegroundColor Red "Error: $($_.Exception.Message)" -NoNewline
    Write-Host -ForegroundColor Red "Copy failed"
}

Write-Host

# build .net40 components
Write-Host "Build net40 components started"

Push-Location "$probeProjectBaseDirectory\Diagnostics.Probes"
& msbuild /t:clean "Diagnostics.Probes.csproj" > $null
& msbuild /t:Build "Diagnostics.Probes.csproj" > $null
if ($?) {
    write-host -ForegroundColor Green "Build net40 components succeded"
}
else {
    Write-host -ForegroundColor Red "Build net40 components failed"
}
Pop-Location

Write-Host "Copying net40 components files"
try {
    New-Item -force ".\net40\content" -type directory > $null
    New-Item -force ".\net40\bin" -type directory > $null
    New-Item -force ".\net40\DbTableTestDescription.json" -type directory > $null
    New-Item -force ".\net40\RsReportTestDescription.json" -type directory > $null
    Copy-Item -Force "$nuspecDirectory\content\net40\*" ".\net40\"
    Copy-Item -Force "$probeProjectBaseDirectory\Diagnostics.Probes\*.svc" ".\net40\content\"
    Copy-Item -Force "..\..\CompileOutput\Debug\net40\*.dll" ".\net40\bin\"
    Move-Item -Force ".\net40\bin\Vcf.EntLib.Diagnostics.SelfTests.DbTables.dll" ".\net40\DbTableTestDescription.json" 
    Move-Item -Force ".\net40\bin\Vcf.EntLib.Diagnostics.SelfTests.DataAccessRSReports.dll" ".\net40\RsReportTestDescription.json" 
    Write-Host -ForegroundColor Green "Copy succeded"
}
catch {
    write-host -ForegroundColor Red "Error: $($_.Exception.Message)" -NoNewline
    Write-Host -ForegroundColor Red "Copy failed"
}

Pop-Location