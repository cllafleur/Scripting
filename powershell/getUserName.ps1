#
#.SYNOPSIS
# This script finds an Active Directory object by GUID.
#.DESCRIPTION
# This script searches the default (or specified) domain for an AD Object based upon a GUID or GUID’s entered.
#.NOTES
# File Name : Get-ADObjectByGUID.ps1
# Author : Karl Mitschke
# Requires : PowerShell Version 2.0
#.LINK
# This script posted to:
# https://unlockpowershell.wordpress.com
#.EXAMPLE
# Get-ADObjectByGuid <guid>,<guid>
# Description
# ———–
# This command searches the default domain for the entered GUID’s
#.EXAMPLE
# <guid>,<guid> | Get-ADObjectByGuid
# Description
# ———–
# This command searches the default domain for the entered GUID’s
#.EXAMPLE
# Get-Content guids.txt | Get-ADObjectByGUID.ps1
# Description
# ———–
# This command gets a list of GUIDS from a file, and searches for each GUID in the default domain.
#.EXAMPLE
# Get-Content guids.txt | Get-ADObjectByGUID.ps1 -Domain contoso.com
# Description
# ———–
# This command gets a list of GUIDS from a file, and searches for each GUID in the contoso.com domain.
#
#.PARAMETER Domain
# The Domain to search (Optional).
#.PARAMETER GUIDS
# The GUID(s) to search for (Required).
#.INPUTS
# One or more GUID’s are required.
# The Domain name to search is optional. If not specified, the script will search the current domain.
#.OUTPUTS
# This script outputs the GUID and Name of an AD Object.
# If the GUID is not found, the script outputs the GUID and a message indicating that the GUID is not found on the domain.
#

param ( 
[Parameter(
Position = 0,
ValueFromPipeline = $true,
ValueFromPipelineByPropertyName = $true,
Mandatory = $true,
HelpMessage = “An array of GUID’s.”
)]
[string[]]$GUIDS,
[Parameter(
Position = 1,
ValueFromPipeline = $false,
ValueFromPipelineByPropertyName = $true,
Mandatory = $false,
HelpMessage = “The domain to search.”
)]
[string]$Domain
)
BEGIN{
}
PROCESS{
function EscapeGuid
{
#finally
$match = “(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})”
$Pattern = ‘”\$4\$3\$2\$1\$6\$5\$8\$7\$9\$10\$11\$12\$13\$14\$15\$16?‘
$EscapedGUID = [regex]::Replace($guid.replace(“-“,“”), $match, $Pattern).Replace(“`””,“”)
return $EscapedGUID
}
$Objects = @()
foreach($GUID in $GUIDS)
{
if ($GUID -match(“^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$”))
{
$EscapedGUID = EscapeGuid
if (!$Domain)
{
$Root = [ADSI]”
}
else
{
$Root = [ADSI]“LDAP://$Domain”
}
$searcher = new-object System.DirectoryServices.DirectorySearcher($root)
$searcher.filter = “(objectGUID=$EscapedGUID)”
$Object = $searcher.FindOne()
if ($Object)
{
$Objects += $guid + ” is “ + $Object.Properties.name
}
else
{
$Objects += $guid + ” is not found on “ + $searcher.SearchRoot.Name[0]
}
}
else
{
Write-Output “$GUID is not a valid GUID. Valid GUID’s are in the format ‘xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'”
}
}
$Objects
}
END{
}