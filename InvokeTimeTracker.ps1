# -----------------------------------------------------------------------------------------------------------------
# Invoke-TimeTracker
# -----------------------------------------------------------------------------------------------------------------

<#
.Synopsis
  Invokes editing the TimeTracker file. Handles some validation and Calculation for the User.
.Description
  Invokes editing the TimeTracker file. Handles some validation and Calculation for the User.
  
  Allows the user to add all time entries for the day. 

  Currently does not check or validate times.
.Example
  PS> Invoke-TimeTracker -Start
  Adds the current time as the start time to the TimeTracker file.
.Example
  PS> Invoke-TimeTracker -Stop
  Adds the current time as the stop time to the TimeTracker file.
.Example 
  PS> Get-Date -Hour 11 -Minute 21 | Invoke-TimeTracker -LunchStart
  Adds the sent datetime to the lunchStart entry.
.Inputs
  System.DateTime
.Outputs
  System.Management.Automation.PSCustomObject

  If -PassThru
.Notes
  Author: endowdly@gmail.com
  FileEncoding: UTF8-BOM
#>
function Invoke-TimeTracker {
    [CmdletBinding()]
    param (
        # The input object is the datetime object of the entry. Default: DateTime.Now
        [Parameter(Mandatory, HelpMessage = 'You must provide a System.DateTime object')] 
        [System.DateTime]
        $InputObject,

        # Indicates the InputObject should be added to the start entry for the date.
        [Parameter(ParameterSetName = 'Start')]
        [switch]
        $Start,

        # Indicates the InputObject should be added to the stop entry for the date.
        [Parameter(ParameterSetName = 'Stop')]
        [switch]
        $Stop, 

        # Indicates the InputObject should be added to the lunch start entry for the date.
        [Parameter(ParameterSetName = 'LunchStart')]
        [switch]
        $LunchStart,

        # Indicates the InputObject should be added to the lunch stop entry for the date.
        [Parameter(ParameterSetName = 'LunchStop')]
        [switch]
        $LunchStop,

        # Pass the resultant action through as an object.
        [Parameter()]
        [switch]
        $PassThru
    )
    
    begin {
        if ($null -eq $Script:TimeTrackerPath) { 
            throw 'No TimeTracker file has been set. Use ''Set-TimeTracker'' to set the file path.'
        } 
    }
    
    process {
        # Todo: Process
    }
    
    end {
    }
}