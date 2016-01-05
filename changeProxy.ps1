

param([Parameter(Mandatory=$true)][string] $proxyConfName)

$vcfDnsBypassProxy = "<local>;localhost;*.vincic-fr.grpsc.net;*.vinci-construction-france.net"

$proxySquid = "172.17.1.16:8080"
$proxyOfficiel = "http://proxy-vcf.vincic-fr.grpsc.net/"
$proxyHome = "127.0.0.1:3128"

$regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

$settings = switch ($proxyConfName) {
    "officiel" { @{ "enable" = 0; "server" = "";"excludedDns"=$vcfDnsBypassProxy; "pac"= $proxyOfficiel} }
    "home"     { @{ "enable" = 1; "server" = $proxyHome; "excludedDns"=$vcfDnsBypassProxy } }
    "disabled" { @{ "enable" = 0; "server" = "" ; "excludedDns"="" } }
    "squid"    { @{ "enable" = 1; "server" = $proxySquid; "excludedDns" = $vcfDnsBypassProxy } }

    default {throw "proxyConfName : officiel, home, disabled, squid"}

}


function setProxySettings {
    param($settings)

    $regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Write-Host "Retrieve the proxy server ..."
    $proxyServer = Get-ItemProperty -path $regKey ProxyServer -ErrorAction SilentlyContinue
    Write-Host $proxyServer
    
    Set-ItemProperty -path $regKey ProxyEnable -value $settings["enable"]
    Set-ItemProperty -path $regkey ProxyServer -value $settings["server"]
    Set-ItemProperty -path $regKey ProxyOverride -value $settings["excludedDns"]
    
    if ($settings.ContainsKey("pac")) {
        Set-ItemProperty -path $regKey AutoConfigURL -value $settings["pac"]
        write-host "pac set to " $settings["pac"]
    }
    else {
        Remove-ItemProperty -path $regKey -Name AutoConfigURL -ErrorAction SilentlyContinue
        write-host "pac removed"
    }
}

setProxySettings($settings)

