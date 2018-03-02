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
# Empty
Remove-Item $ZipOut\*.xml

# Unzip to TempDir
If ($logon -eq "Yes") { Write-Log "Unzipping import files" }
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
	$DfwConfigHash = [xml](Get-Content $DfwConfigExportFile)
}
Catch {
	If ($logon -eq "Yes") { Write-Log "Cannot import $_" }
	Throw "Unable to import capture bundle content.  $_"
}

# IP Set
$count=0
$countskip=0
$countadd=0 
If ($logon -eq "Yes") { Write-Log "******** Importing IPSets" }
ForEach ($IpSetId in $IpSetHash.Keys){
	[System.Xml.XmlDocument]$IpSetDoc = $IpSetHash.Item($IpSetId)
	$IPSet = $IpSetDoc.Ipset
	$IPSetname = $IPSet.name
	$IPSetvalue = $IPSet.value
	If ($logon -eq "Yes") { Write-Log "Found IPSet: $IPSetname with value: $IPSetvalue" }
	# Check if exists, in $Connection
	If ($logon -eq "Yes") { Write-Log "Checking for existing IpSet" }
	$itemIpSetfromNSX = Get-NsxIpSet -name "$IPSetname" -connection $Connection
	If (!$itemIpSetfromNSX){
		# doesnotexist
		If ($logon -eq "Yes") { Write-Log "[ADDING] IPSet: $IPSetname will be added in NSX" }
		# New
		New-NsxIpSet -name "$IPSetname" -IPAddress "$IPSetvalue"
		$countadd=$countadd+1
	}else{
		#doesexist skip
		If ($logon -eq "Yes") { Write-Log "[SKIP] IPSet: $IPSetname exists in NSX, skipping...." }
		$countskip=$countskip+1
	}
$count=$count+1		
}
If ($logon -eq "Yes") { Write-Log "+++++ Finished importing IPSets" }
If ($logon -eq "Yes") { Write-Log "++    Total IPSets: $count" }
If ($logon -eq "Yes") { Write-Log "++    Total IPSets Skipped: $countskip" }
If ($logon -eq "Yes") { Write-Log "++    Total IPSets Add: $countadd" }

# Services
$count=0
$countskip=0
$countadd=0 
If ($logon -eq "Yes") { Write-Log "******** Importing Services" }
ForEach ($ServicesId in $ServicesHash.Keys){
	[System.Xml.XmlDocument]$ServicesDoc = $ServicesHash.Item($ServicesId)
	$Services = $ServicesDoc.application
	$Servicesname = $Services.name
	$Servicesdescription = $Services.description
	$Servicesprotocol = $Services.element.applicationProtocol
	$Servicesvalue = $Services.element.value
	If ($logon -eq "Yes") { Write-Log "Found Service: $Servicesname with value: $Servicesvalue (Prot: $Servicesprotocol Descr: $Servicesdescription" }
	# Check if exists, in $Connection
	If ($logon -eq "Yes") { Write-Log "Checking for existing Services" }
	$itemServicesfromNSX = Get-NsxService -name "$Servicesname" -connection $Connection
	If (!$itemServicesfromNSX){
		# doesnotexist
		If ($logon -eq "Yes") { Write-Log "[ADDING] Services: $Servicesname will be added in NSX" }
		# New
		New-NsxService -Name "$Servicesname" -Protocol "$Servicesprotocol" -port "$Servicesvalue" -Description "$Servicesdescription"
		$countadd=$countadd+1
	}else{
		#doesexist skip
		If ($logon -eq "Yes") { Write-Log "[SKIP] Services: $Servicesname exists in NSX, skipping...." }
		$countskip=$countskip+1
	}
$count=$count+1	
}
If ($logon -eq "Yes") { Write-Log "+++++ Finished importing Services" }
If ($logon -eq "Yes") { Write-Log "++    Total Services: $count" }
If ($logon -eq "Yes") { Write-Log "++    Total Services Skipped: $countskip" }
If ($logon -eq "Yes") { Write-Log "++    Total Services Add: $countadd" }

$count=0
$countskip=0
$countadd=0 
If ($logon -eq "Yes") { Write-Log "******** Importing ServiceGroups" }
# Errors are shown on screen when importing servicegroups, however groups are imported. Surpressing for now
ForEach ($ServiceGrpId in $ServiceGroupHash.Keys){
	[System.Xml.XmlDocument]$ServiceGrpDoc = $ServiceGroupHash.Item($ServiceGrpId)
	$ServiceGrp = $ServiceGrpDoc.applicationGroup
	$ServiceGrpname = $ServiceGrp.name
	$ServiceGrpdescription = $ServiceGrp.description
	$ServiceGrpmember = $ServiceGrp.member
	If ($logon -eq "Yes") { Write-Log "Found ServiceGroup: $ServiceGrpname with Descr: $ServiceGrpdescription" }
	# Check if exists, in $Connection
	If ($logon -eq "Yes") { Write-Log "Checking for existing ServiceGroups" }
	$itemServiceGrpfromNSX = Get-NsxServiceGroup -name "$ServiceGrpname" -connection $Connection
	If (!$itemServiceGrpfromNSX){
		# doesnotexist
		If ($logon -eq "Yes") { Write-Log "[ADDING] ServiceGroup: $ServiceGrpname will be added in NSX" }
		# New Add Group and than add members one by one
		New-NsxServiceGroup -name "$ServiceGrpname"
		# Got to find ID in destination for each member
		Foreach ($member in $ServiceGrpmember){
			$membername = $member.name
			If ($logon -eq "Yes") { Write-Log "[ADDING] ServiceGroup: $ServiceGrpname add member $membername" }
			# Get the service id
			$SvcGrChildId = Get-NsxService -name "$membername" -ErrorAction SilentlyContinue
			If ($logon -eq "Yes") { Write-Log "[ADDING] ServiceGroup: $membername add memberID $SvcGrChildId" }
			Get-NsxServiceGroup -name "$ServiceGrpname" | Add-NsxServiceGroupMember "$SvcGrChildId" -ErrorAction SilentlyContinue	
		}
		#New
		$countadd=$countadd+1
	}else{
		#doesexist skip
		If ($logon -eq "Yes") { Write-Log "[SKIP] Service Group: $Servicegrpname exists in NSX, skipping...." }
		$countskip=$countskip+1
	}
$count=$count+1	
}
If ($logon -eq "Yes") { Write-Log "+++++ Finished importing ServiceGroups" }
If ($logon -eq "Yes") { Write-Log "++    Total ServiceGroups: $count" }
If ($logon -eq "Yes") { Write-Log "++    Total ServiceGroups Skipped: $countskip" }
If ($logon -eq "Yes") { Write-Log "++    Total ServiceGroups Add: $countadd" }

$count=0
$countskip=0
$countadd=0 
If ($logon -eq "Yes") { Write-Log "******** Importing Security Groups" }
# Errors are shown on screen when importing group members, however groups are imported. Surpressing for now
# Only Synchronize IP Set Members
ForEach ($SecurityGrpId in $SecurityGroupHash.Keys){
	[System.Xml.XmlDocument]$SecurityGrpDoc = $SecurityGroupHash.Item($SecurityGrpId)
	$SecurityGrp = $SecurityGrpDoc.securitygroup
	$SecurityGrpname = $SecurityGrp.name
	$SecurityGrpdescription = $SecurityGrp.description
	$SecurityGrpmember = $SecurityGrp.member
	If ($logon -eq "Yes") { Write-Log "Found Security Group: $SecurityGrpname with Descr: $SecurityGrpdescription" }
	# Check if exists, in $Connection
	If ($logon -eq "Yes") { Write-Log "Checking for existing Security Groups" }
	$itemSecurityGrpfromNSX = Get-NsxSecurityGroup -name "$SecurityGrpname" -connection $Connection
	If (!$itemSecurityGrpfromNSX){
		# doesnotexist
		If ($logon -eq "Yes") { Write-Log "[ADDING] Security Group: $SecurityGrpname will be added in NSX" }
		# New Add Group and than add members one by one
		New-NsxSecurityGroup -name "$SecurityGrpname"
		# Got to find ID in destination for each member
		Foreach ($member in $SecurityGrpmember){
			$membername = $member.name
			If ($logon -eq "Yes") { Write-Log "[ADDING] Security Group: $SecurityGrpname add member $membername" }
			Get-NsxSecurityGroup -name "$SecurityGrpname" | Add-NsxSecurityGroupMember -Member (Get-NsxIPSet -name "$membername" -ErrorAction SilentlyContinue) -ErrorAction SilentlyContinue	
		}
		#New
		$countadd=$countadd+1
	}else{
		#doesexist skip
		If ($logon -eq "Yes") { Write-Log "[SKIP] Security Group: $SecurityGrpname exists in NSX, skipping...." }
		$countskip=$countskip+1
	}
$count=$count+1	
}
If ($logon -eq "Yes") { Write-Log "+++++ Finished importing Security Groups" }
If ($logon -eq "Yes") { Write-Log "++    Total Security Groups: $count" }
If ($logon -eq "Yes") { Write-Log "++    Total Security Groups Skipped: $countskip" }
If ($logon -eq "Yes") { Write-Log "++    Total Security Groups Add: $countadd" }

# Cleanup Unzipped Xml
Remove-Item $ZipOut\*.xml

# EOF