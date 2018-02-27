# NsxSynchronization
Synchronization between NSX instances

This script takes input from the user to synchronize a source and destination NSX Manager with DFW rules to be specified in a section.

This version currenty imports IPSets and their values

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
  
  
