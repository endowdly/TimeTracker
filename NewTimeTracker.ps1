# ----------------------------------------------------------------------------------------------------------------------
# New-TimeTracker
# ----------------------------------------------------------------------------------------------------------------------

<#
.Synopsis
  Creates a New TimeTracker File.
.Description
  Creates a new TimeTracker File. This is a fancy wrapper for New-Item.

  The abbreviated EBNF for a TimeTracker File: 

  timetracker = (work-duration, lunch-duration, tracker)
  work-duration = System.Double
  lunch-duration = System.Double 
  tracker = Hashtable<date-key, tracker-entry>
  
  date-key = "year", "month", "day"
  tracker-entry = start, stop, [lunch-start], [lunch-stop], overtime 
.Example
  PS> New-TimeTracker -Force -WorkDuration 8.5 -Lunch 0.5
  Creates timetracker.json in the current directory, overwritting any existing file. It sets the Standard work day
  Length to 8.5 hours and the mandated Lucnh Duration to half an hour. 
.Example
  PS> New-TimeTracker -Path $env:USERNAME/Desktop -Name tracker.json
  Creates tracker.json on the current user's Desktop. It uses the defaults and sets the Standard work day
  Length to 8.0 hours and the mandated Lucnh Duration to half an hour.
.Link
  New-Item
.Outputs
  System.IO.FileInfo
.Notes
  Author: ryan.dowd@navy.mil
#>
function New-TimeTracker { 
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]  # Handled by the wrapped Command
    [CmdletBinding(DefaultParameterSetName = 'PathSet', 
                   SupportsShouldProcess,
                   ConfirmImpact = 'Medium')]
    [OutputType([System.IO.FileInfo])]                   
    param (
        # The Path of the File or the its intended Directory. Default: cwd
        [Parameter(ParameterSetName = 'PathSet', Position = 0, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'NameSet', Position = 0, ValueFromPipelineByPropertyName)]
        [System.String[]]
        $Path = $PWD,

        # The name of the File. Default: 'timetracker.json'
        [Parameter(ParameterSetName = 'NameSet', Position = 1, ValueFromPipelineByPropertyName)]
        [AllowNull()]
        [AllowEmptyString()]
        [System.String]
        $Name = 'timetracker.json',

        # Force an existing File to be overwritten.
        [Switch]
        $Force,
        
        # The Standard Work Day Duration in Hours. Default: 8.0
        [Parameter(ParameterSetName = 'PathSet', Position = 1, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'NameSet', Position = 2, ValueFromPipelineByPropertyName)] 
        [ValidateRange(0.0, 24.0)]
        [System.Double]
        $WorkDuration = 8.0,

        # An OSHA Mandated Lunch break which is Added to the Work Day in Hours. Default: 0.5
        [Parameter(ParameterSetName = 'PathSet', Position = 2, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'NameSet', Position = 3, ValueFromPipelineByPropertyName)] 
        [ValidateRange(0.0, 24.0)]
        [System.Double]
        $LunchDuration = 0.5
    )
    
    begin {      
        $TimeTracker = @{
            WorkDuration = $WorkDuration
            LunchDuration = $LunchDuration

            Tracker = @{ 
                <# Example Entry: 

                YYYYmmDD = @{
                    Start = YYYY-mm-DDTHH:MM:ss.sssssss+OFFSET
                    Stop = YYYY-mm-DDTHH:MM:ss.sssssss+OFFSET
                    LunchStart = YYYY-mm-DDTHH:MM:ss.sssssss+OFFSET   # Optional
                    LunchStop = YYYY-mm-DDTHH:MM:ss.sssssss+OFFSET   # Optional
                    Overtime = Stop - Start - Lunch
                } 

                #> 
            }
        } 
    
        # Update the cloned template data with instance parameters
        $Value = ConvertTo-Json $TimeTracker -Depth 3 

        # Cleanup PSBoundParameters so we can just use New-Item
        [void] $PSBoundParameters.Remove('WorkDuration')
        [void] $PSBoundParameters.Remove('LunchDuration')
        [void] $PSBoundParameters.Add('Value', $Value)

        try {
            # Ensure we don't call a user defined `New-Item`
            $WrappedCmd = $ExecutionContext.InvokeCommand.GetCmdlet('New-Item')
            $Cmd = { & $WrappedCmd -Type File @PSBoundParameters }
            $CmdPipeline = $Cmd.GetSteppablePipeline()
            [void] $CmdPipeline.Begin($PSCmdlet) 
        }
        catch {
            throw $_
        }
    }
    
    process {
        try {
            $CmdPipeline.Process($_)
        }
        catch {
           throw $_ 
        }
    }
    
    end {
        try {
            $CmdPipeline.End()
        }
        catch {
            throw $_ 
        }
    }
}