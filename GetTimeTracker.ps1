# -----------------------------------------------------------------------------------------------------------------
# Get-TimeTracker
# -----------------------------------------------------------------------------------------------------------------

<#
.Synopsis
  Returns information about a TimeTracker File.
.Description
  Returns the currently set TimeTracker File as a FileInfo object. With switches, can return more information.

  Use -Raw to get the raw text of the file.
  Use -AsObject to get the entire file as a custom object.
.Example
  PS> Get-TimeTracker
  Returns FileInfo for the current TimeTracker file. 
.Example
  PS> Get-TimeTracker -AsObject
  Returns FileInfo for the current TimeTracker file. 
.Link
  Set-TimeTracker
.Notes
  Author: endowdly@gmail.com
  FileEncoding: UTF8-BOM

  I had thought about using paths to allow explicit files as input. However, to keep things simple, I decided 
  that a 'class' module approach would be better.

  If a user wants to view or manipulate the data of a different file, they can use core commands to accomplish
  that. Keeping Set- and Get-TimeTracker to be within the scope of the module seems more in line with the idea
  of "small, consumable commands".
#>
function Get-TimeTracker {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        # Gets the raw text of the TimeTracker File.
        [Parameter(ParameterSetName = 'RawOutput')]
        [switch]
        $Raw,

        # Gets the entire TimeTracker File as an object.
        [Parameter(ParameterSetName = 'ObjectOutput')]
        [switch]
        $AsObject)
    
    begin {
        # Set-TimeTracker does a lot of checking, so assume this path is a valid path.
        $Path = $script:TimeTrackerPath
    }
    
    process {
        <# Empty #>
    }
    
    end {
        switch ($PSCmdlet.ParameterSetName) {
            RawOutput { Get-Content $Path -Raw }
            ObjectOutput { Get-Content $Path | ConvertFrom-Json }
            Default { [System.IO.FileInfo] $Path }
        }
    }
}