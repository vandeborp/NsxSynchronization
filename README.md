# NsxSynchronization
Synchronization between NSX instances

This script takes input from the user to synchronize a source and destination NSX Manager with DFW rules to be specified in a section.

This version currenty imports IPSets and their values, Services, Servicegroups, Securitygroups and DFW sections (and rules) if the user agrees to importing.

DEPENDENCIES
  VMware.PowerCLI
  PowerNSX
  NSxObjectCapture.ps1 taken from DiagramNSX; Changed the export from user profile to the current location
  
OUTPUT
  Log file
  Zip XML Bundle of source NSX manager
  
To Do
  Other components to destination.
  Ability to input which DFW sections to synchronize (for example only management Section)
  
  
Flow:
Structure:
Input NSX Manager Source
Input NSX Manager Destination
Specify Sections
Connect NSX Manager Source
Export Source to XML's and zip bundle
Connect NSX Manager Destination
Extract source XMLs
Import Source to DFW -> selection of section? -> Ask user input (Y import / N skip section) later met Param
	- IpSet done
	- SecurityGroup only import group
		will only import IpSet 
Remove temp XML’s, Source zip bundled remain saved


Interested in:
	- IpSetExport
	- SecurityGroupExport
	- ServiceGroupExport
	- ServicesExport
	- DfwConfigExport


ABSOLUTELY NO WARRANTY. If you haven't tested before running this in a production, dont start whining.
  
  
