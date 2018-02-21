<# 
.DESCRIPTION 
    This script takes input from the Capture script and parses this to an other NSX instance
	
.NOTES
	File Name:NsxObjectImport.ps1
	
.OPTIONS
	None yet, but should also be able to be called from script/task
	
.LINK
	Github to be created https://github.com/Paikke/NsxSynchronization
	
.DEPENDENCIES
    VMware.PowerCLI
	PowerNSX
	NsxSyncronisation.ps1 for running this script
	NSxObjectCapture.ps1 taken from DiagramNSX; Changed the export from user profile to the current location
	
.INPUT 
	Requires user interaction during script for NSX connection parameters
	
.OUTPUT
	To be included - Log file.
#>

param (

    [pscustomobject]$Connection=$DefaultNsxConnection,
	[string]$CaptureBundle
)

If ( (-not $Connection) -and ( -not $Connection.ViConnection.IsConnected ) ) {

    throw "No valid NSX Connection found.  Connect to NSX and vCenter using Connect-NsxServer first.  You can specify a non default PowerNSX Connection using the -connection parameter."

}
If (-not $CaptureBundle) {
	throw "No capture Bundle found for import. Use -CaptureBundle to set."
}

# Settings
$logon = "Yes" # Do we want the script to log Yes or No
$logFile = "NsxObjectImport.log" # Log File location

# Dot Source Functions.ps1
. "$PSScriptRoot\Functions.ps1"



#########
# Run Baby Run
#########

## Init Log with current time
If ($logon -eq "Yes") { Write-Log "Starting engines" }
If ($logon -eq "Yes") { Write-Log "Using $CaptureBundle as imput" }
write-host -ForeGroundColor Green "PKUnzip ;) $CaptureBundle"

## Validate CaptureBundle
If ( -not ( test-path $CaptureBundle )) {
	If ($logon -eq "Yes") { Write-Log "Specified $CaptureBundle not found" }
	throw "Specified File $CaptureBundle not found."
}

$ZipOut = "$PSScriptRoot\NSX2bImported"

# Unzip to TempDir
Try {
	Add-Type -assembly "System.IO.Compression.Filesystem"
	[System.IO.Compression.ZipFile]::ExtractToDirectory($CaptureBundle, $ZipOut)
}
Catch {
	If ($logon -eq "Yes") { Write-Log "Cannot unzip $CaptureBundle" }
	Throw "Unable to extract capture bundle. $_"
}

# Here we start with
# IpSetExport
# SecurityGroupExport
# ServiceGroupExport
# ServicesExport
# DfwConfigExport
$IpSetExportFile = "$ZipOut\IpSetExport.xml"
$SecurityGroupExportFile = "$ZipOut\SecurityGroupExport.xml"
$ServiceGroupExportFile = "$ZipOut\ServiceGroupExport.xml"
$ServicesExportFile = "$ZipOut\ServicesExport.xml"
$DfwConfigExportFile = "$ZipOut\DfwConfigExport.xml"

Try {
	$IpSetHash = Import-CliXml $IpSetExportFile
	$SecurityGroupHash = Import-CliXml $SecurityGroupExportFile
	$ServiceGroupHash = Import-CliXml $ServiceGroupExportFile
	$ServicesHash = Import-CliXml $ServicesExportFile
	$DfwConfigHash = Import-CliXml $DfwConfigExportFile

}
Catch {
	If ($logon -eq "Yes") { Write-Log "Cannot import $CaptureBundle" }
	Throw "Unable to import capture bundle content.  Is this a valid capture bundle? $_"
}


