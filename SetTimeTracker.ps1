# ----------------------------------------------------------------------------------------------------------------------
# Set-TimeTracker
# ----------------------------------------------------------------------------------------------------------------------

<#
.Synopsis
  Set the TimeTracker Path.
.Description
  Set the module variable, TimeTrackerPath. This function sets internal TimeTrackerPath to Path after confirmation
  tests. Use this function to set the path used for implicit operations with other TimeTracker noun Functions.

  Path must be an existing File, it must be valid Json File, and it must be in a TimeTracker Format.

  Path accepts Wildcards and does not have a default Value.
.Example
  PS> Set-TimeTracker -Path timetracker
  Sets TimeTrackerPath to $pwd/timetracker, where $pwd is the fully qualified current working directory.
.Example
  PS> Set-TimeTracker -Path ~/Doc*/Trackers/time*
  Sets TimeTrackerPath to the resolved path of Path, assuming Path exist, and points to a valid TimeTracker file.
.Example
  PS> New-TimeTracker -Path $Home\Desktop -Name .timetracker | Set-TimeTracker
  Pipe a newly created TimeTracker file to be set after creation.
.Inputs
  System.String

  A string that contains the Path.
.Outputs
  System.IO.FileInfo

  Returns a FileInfo object for the resolved path if you specify -PassThru
.Notes
  Author: endowdly@gmail.com
  FileEncoding: UTF8-BOM
#>
function Set-TimeTracker { 
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param (
        # Set the current TimeTracker to this file Path. WildCards permitted.
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
        [System.String]
        $Path,

        # Return the FileInfo Object of the new TimeTracker File
        [Parameter()]
        [switch]
        $PassThru
    )

    begin {
        $TimeTrackerProperties = 'WorkDuration', 'LunchDuration', 'Tracker'

        # Pass the resolved Path if it is valid
        filter Confirm-TimeTrackerPath {
            $_ | Resolve-Path -ErrorAction Stop
        }

        # Pass the resolved Path if it is valid Json AND has valid TimeTracker Properties
        filter Confirm-TimeTrackerFile {
            $f = $_

            try {
                $fName = Split-Path $f -Leaf
                $f |
                    Get-Content |
                    ConvertFrom-Json -ErrorAction Stop |
                    Get-Member -MemberType NoteProperty |
                    ForEach-Object { 
                        if ($_.Name -notin $TimeTrackerProperties) {
                            throw "$fName is not a valid TimeTracker file! Unknown Property: $( $_.Name )"
                        }
                    }

                $f
            }
            # Try to catch Malformed Json here
            catch [System.ArgumentException] {
                Write-Error -Message "Malformed Json! Cannot parse '$f'" -ErrorAction Stop
            }
            catch {
                Write-Error $_ -ErrorAction Stop
            }
        }

        # Set the module Variable 'TimeTrackerPath' to the input Path
        filter Update-TimeTracker {
            $script:TimeTrackerPath = $_

            if ($PassThru) {
                [System.IO.FileInfo] $_
            }
        }
    }

    process {
        $Validated =
            $Path |
                Confirm-TimeTrackerPath |
                Confirm-TimeTrackerFile |
                Convert-Path

        if ($PSCmdlet.ShouldProcess("Internal TimeTrackerPath <- $Validated")) {
            $Validated | Update-TimeTracker
        }
    }

    end {
        <# Empty #>
    }
}