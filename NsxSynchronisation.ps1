<# 
.DESCRIPTION 
    This script takes input from the user to syncronize a source and destination NSX Mgr
	with DFW rules to be specified in a section
	
.NOTES
	File Name:NsxSynchronization.ps1
	
.OPTIONS
	None yet, but should also be able to be called from script/task
	
.LINK
	Github to be created https://github.com/Paikke/NsxSynchronization
	
.DEPENDENCIES
    VMware.PowerCLI
	PowerNSX
	NSxObjectCapture.ps1 taken from DiagramNSX; Changed the export from user profile to the current location
	
.INPUT 
	Requires user interaction during script for NSX connection parameters
.OUTPUT
	Export settings in zipped XML report. 
	To be included - Log file.
#>

# Settings
$logon = "Yes" # Do we want the script to log Yes or No
$logFile = "NsxSynchronization.log" # Log File location

# Dot Source Functions.ps1
. "$PSScriptRoot\Functions.ps1"

# Parameter for NsxObjectCapture.ps1 is Connection

#########
# Run Baby Run
#########

## Init Log with current time
If ($logon -eq "Yes") { Write-Log "Starting engines" }

# Get input from user about
# NSX Manager
$nsxManager = Read-Host ("Source vCenter connected to NSX (FQDN/IP)")
If(!($nsxManager)){
	# no manager throw error and exit
	If ($logon -eq "Yes") { Write-Log "[ERROR] Asked user about vCenter/NSX manager. Got no usable response: $nsxManager" }
	throw "Asked user about vCenter/NSX manager. Got no usable response: $nsxManager"
}
If ($logon -eq "Yes") { Write-Log "Asked user about NSX manager. Got response: $nsxManager" }
# User
$nsxUser = Read-Host ("SSO NSX User to connect and with permissions to add")
If(!($nsxUser)){
	# no user throw error and exit
	If ($logon -eq "Yes") { Write-Log "[ERROR] Asked user about SSO NSX user. Got no usable response: $nsxUser" }
	throw "Asked user about SSO NSX User. Got no usable response: $nsxUser"
}
If ($logon -eq "Yes") { Write-Log "Asked user about SSO NSX User. Got response: $nsxUser" }
# Pass
# Will not log password
$nsxPass = Read-Host ("SSO user Password to connect")
If(!($nsxPass)){
	# no Pass throw error and exit
	If ($logon -eq "Yes") { Write-Log "[ERROR] Asked user about password. Got no usable response: <not logged>" }
	throw "Asked user about password. Got no usable response: $nsxPass"
}
If ($logon -eq "Yes") { Write-Log "Asked User about NSX Pass. Got response: <input not logged>" }
# Trust certificate?

# Open Connection
# Use as -connection $NSXConnection is the remainder of commands
If ($logon -eq "Yes") { Write-Log "Opening connection to NSX Manager" }
$NSXConnection = Connect-NsxServer -vCenterServer $nsxManager -username $nsxUser -Password $nsxPass #-DefaultConnection:$false

# Use this in connection to NsxObjectCapture.ps1
# Again dot source
If ($logon -eq "Yes") { Write-Log "Running Export on Source NSXConnection" }
. ./NsxObjectCapture.ps1 -Connection $NSXConnection


#EOF