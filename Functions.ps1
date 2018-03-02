# Function Declaration
function Write-Log 
{ 
    <# 
    .SYNOPSIS 
        This function creates or appends a line to a log file. 
 
    .PARAMETER  Message 
        The message parameter is the log message you'd like to record to the log file. 
 
    #> 
    [CmdletBinding()] 
    param ( 
        [Parameter(Mandatory)] 
        [string]$Message 
    ) 
     
    try 
    { 
        $DateTime = Get-Date -Format "dd-MM-yy HH:mm:ss"  
        Add-Content -Value "$DateTime - $Message" -Path "$logFile" 
    } 
    catch 
    { 
        Write-Error $_.Exception.Message 
    } 
}

# End Function Declaration