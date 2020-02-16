# -----------------------------------------------------------------------------------------------------------------
# Update-TimeTracker
# -----------------------------------------------------------------------------------------------------------------

<#
.Synopsis
  Updates tracker data in a TimeTracker file.
.Description
  Updates tracker data in a TimeTracker file.

  Private function.
.Example
  PS> Update-TimeTracker $Data
  Passing the input object.
.Example
  PS> $Data | Update-TimeTracker
  Passing the input object on the pipe.
.Notes
  Author: endowdly@gmail.com 
  FileEncoding: UTF8-BOM
#>
function Update-TimeTracker {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # The Data to change.
        [Parameter(ValueFromPipeline, Mandatory, HelpMessage = 'Enter tracker object to change.')] 
        $InputObject,
        
        # Pass the result out.
        [Parameter()]
        [switch]
        $PassThru)
    
    begin {
        $TimeTracker = Get-TimeTracker -AsObject
        $Path = Get-TimeTracker
    }
    
    process {
        $TimeTracker.Tracker = $InputObject

        if ($PSCmdlet.ShouldProcess($Path.Name)) {
            $TimeTracker | 
                ConvertTo-Json -Depth 3 | 
                Set-Content -Path $Path -Encoding UTF8 -PassThru:$PassThru
        }
    }
    
    end {
        <# Empty #>
    }
}
