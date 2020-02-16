# -----------------------------------------------------------------------------------------------------------------
# Set-TimeEntry
# -----------------------------------------------------------------------------------------------------------------

<#
.Synopsis
  Sets a time to the tracker entry in the TimeTracker file.
.Description
  Sets a time to the tracker entry in the TimeTracker file.

  This is a private function.
.Example
  PS> Set-TimeEntry -Start
  Adds the current time as a start time to todays date entry in the current TimeTracker file.
.Example
  PS> Get-Date -Hour 07 -Minute 42 | Set-TimeEntry -Start
  Adds 7:42a to the specified date in the current TimeTracker file.
.Example
  PS> Set-TimeEntry $dt -Stop
  Adds the datetime object in the variable 'dt' to the current TimeTracker file.
.Inputs
  System.DateTime
.Outputs
  System.Management.Automation.PSCustomObject
.Notes
  Author: endowdly@gmail.com
  FileEncoding: UTF8-BOM

  The pipeline slows things down a little, but these aren't expensive operations.
  This was a pain to write because I like to manipulate 'object' like entities as hashes.
  I do this for their convenience in getting and setting 'properties'. 
  True object properties are a pain to manipulate... and very slow. 
  However, ConvertFrom-Json returns an object and only supports strings. So I had three different kinds of 
  conversions happening:
    object <-> hashtable
    datetime <-> string
    timespan <-> string

  The result is the number of helper functions and the pipeline. Oh well. 
#>

function Set-TimeEntry {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param (
        # A DateTime object representing the date and time of the stop.
        [Parameter(ValueFromPipeline, Mandatory, HelpMessage = 'You must enter an DateTime InputObject')]
        [System.DateTime]
        $InputObject,

        # Indicates InputObject should be a Start time.
        [Parameter(ParameterSetName = 'Start', ValueFromPipelineByPropertyName)]
        [switch]
        $Start,

        # Indicates InputObject should be a Stop time.
        [Parameter(ParameterSetName = 'Stop', ValueFromPipelineByPropertyName)]
        [switch]
        $Stop,

        # Indicates InputObject is a LunchStart time.
        [Parameter(ParameterSetName = 'LunchStart', ValueFromPipelineByPropertyName)]
        [switch]
        $LunchStart,

        # Indicates InputObject is a LunchStop time.
        [Parameter(ParameterSetName = 'LunchStop', ValueFromPipelineByPropertyName)]
        [switch]
        $LunchStop,

        # Passes an information object containing the TimeEntry and Overtime.
        [Parameter()]
        [switch]
        $PassThru,

        # Overwrites an existing date entry.
        [Parameter()]
        [switch]
        $Force)

    begin { 
        $CanUpdate =
            if ($PSCmdlet.ShouldProcess('TimeTracker', 'Update')) {
                $true
            }
            else {
                $false
            }

        $Obj = @{
            Input         = $null
            EntryKey      = $null
            Entry         = $null
            Tracker       = $null
            UpdateFlag    = $CanUpdate
            EntryExists   = $null
            LunchDuration = $null
            WorkDuration  = $null
            TotalDuration = $null
        }

        function ConvertTo-Hashtable ($obj) {
            $ht = @{}

            foreach ($property in $obj.PSObject.Properties.Name) {
                $ht[$property] = $obj.$property
            }

            $ht
        }

         # Todo: Think of a better name for this function
         function ConvertTo-String ($ht) {
            $new = @{}

            foreach ($kv in $ht.GetEnumerator()) {
                if ($kv.Value -is [System.DateTime]) {
                    $new[$kv.Key] = $kv.Value.ToString('o')
                }
                else {
                    $new[$kv.Key] = $kv.Value.ToString()
                }
            }

            $new
        }

        # Todo: Think of a better name for this function
        function ConvertFrom-String ($ht) {
            $new = @{}

            foreach ($kv in $ht.GetEnumerator()) {
                switch ($kv.Value) {
                    { $kv.Value -as [System.DateTime] } { $new[$kv.Key] = [System.DateTime] $kv.Value } 
                    { $kv.Value -as [System.TimeSpan] } { $new[$kv.Key] = [System.TimeSpan] $kv.Value } 
                    default { $new[$kv.Key] = $kv.Value }
                }
            }

            $new
        }

        filter Set-Input {
            $Obj.Input = $_
            $Obj.EntryKey = $_.ToString('yyyyMMdd')

            $Obj
        }

        # More like ... set... stuff...
        filter Set-Tracker {
            $data = Get-TimeTracker -AsObject
            $_.Tracker = ConvertTo-Hashtable $data.Tracker
            $_.TotalDuration = [timespan]::FromHours($data.WorkDuration + $data.LunchDuration)
            $_.WorkDuration = $data.WorkDuration -as [System.Double]
            $_.LunchDuration = $data.LunchDuration -as [System.Double]

            $_
        }

        filter Test-Entry {
            $_.EntryExists = $_.Tracker.ContainsKey($_.EntryKey)

            $_
        }

        filter Get-Entry {
            if ($_.EntryExists) {
                $_.Entry = ConvertTo-Hashtable $_.Tracker.($_.EntryKey)
            } 
            else {
                $_.Entry = @{}
            }

            $_
        }

        filter Set-Entry {
            $in = $_.Input
            $value = ConvertFrom-String $_.Entry 
            $d = $_.TotalDuration
            $ot = {
                if ($null -eq $value.LunchStart -and $null -eq $value.LunchStop) {
                    ($value.Stop - $value.Start) - $d
                }
                else {
                    ($value.Stop - $value.Start) - ($value.LunchStop - $value.LunchStart) - $d
                }
            }
            $start = {
                $value.Start = $in
            }
            $stop = {
                $value.Stop = $in
                $value.Overtime = & $ot
            }
            $lunchStart = {
                $value.LunchStart = $in
            }
            $lunchStop = {
                $value.LunchStop = $in
            }

            switch ($PSCmdlet.ParameterSetName) {
                Start { & $start }
                Stop { & $stop }
                LunchStart { & $lunchStart }
                LunchStop { & $lunchStop }
            }

            $_.Entry = $value
            $_
        }

        filter Add-Entry {
            $_.Tracker[$_.EntryKey] = ConvertTo-String $_.Entry
            $data = [PSCustomObject]$_.Tracker

            if ($_.UpdateFlag) {
                Update-TimeTracker $data
            }

            $_
        }

        filter Get-Output { 
            $in = ConvertFrom-String $_.Entry
            $wd = $_.WorkDuration
            $ld = $_.LunchDuration
            $start = {
                [PSCustomObject]@{
                    StartTime     = $in.Start.ToString('t')
                    EstimatedStop = $in.Start.AddHours($wd + $ld).ToString('t')
                }
            }
            $stop = {
                [PSCustomObject]@{
                    StartTime = $in.Start.ToString('t')
                    StopTime  = $in.Stop.ToString('t')
                    Overtime  = $in.Overtime.ToString('h\:m')
                }
            }
            $lunchStart = {
                [PSCustomObject]@{
                    LunchStart    = $in.LunchStart.ToString('t')
                    EstimatedStop = $in.LunchStart.AddHours($ld).ToString('t')
                }
            }
            $lunchStop = {
                [PSCustomObject]@{
                    LunchStop = $in.LunchStop.ToString('t')
                    Duration  = ($in.LunchStop - $in.LunchStart).ToString('h\:m')
                }
            }

            switch ($PSCmdlet.ParameterSetName) {
                Start { & $start }
                Stop { & $stop }
                LunchStart { & $lunchStart }
                LunchStop { & $lunchStop }
            }
        }

        filter Write-ThisOutput {
            if ($PassThru) {
                $_
            }
        }
    }

    process {
        $InputObject | 
            Set-Input |
            Set-Tracker | 
            Test-Entry |
            Get-Entry |
            Set-Entry |
            Add-Entry |
            Get-Output |
            Write-ThisOutput
    }

    end {
        <# Empty #>
    }
}
