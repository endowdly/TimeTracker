function Invoke-TimeTracker {
    [CmdletBinding(SupportsShouldProcess)]
    [Alias('Clock', 'TimeTracker')]

    param ( 
        [switch] $Pause,

        [Alias('Resume')]
        [switch] $Play,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('In')]
        [datetime] $StartTime,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('Out')]
        [datetime] $StopTime,

        [Parameter(ValueFromPipelineByPropertyName)]
        [datetime] $StartLunch,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='Stop')]
        [datetime] $StopLunch,

        [Parameter(ValueFromPipelineByPropertyName)]
        [timespan] $WorkDayLength = (New-TimeSpan -Minutes $TimeTracker.WorkDayMinutes),
        
        [switch] $Silent,
        [switch] $PassThru,
        
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='Stop')]
        [Alias('PSPath')]
        [ValidateScript({ Assert-Path $_ })]
        [string] $Path = $TimeTracker.TrackerPath) 

    Write-Debug $PSCmdlet.ParameterSetName

    if (-not (Test-WorkDay) -and $PSCmdlet.ShouldProcess($Resources.InvokeTimeTracker.ShouldProcess.WorkDay)) {

        $Current.WorkDayLength = $WorkDayLength                                                             

        $Reports.Push($Resources.InvokeTimeTracker.Information.SettingWorkDay -f $WorkDayLength.TotalHours)
    } 

    switch ($PSBoundParameters.Keys) {
        StartTime {
            if (-not (Test-StartTime) -or
                $PSCmdlet.ShouldContinue($Resources.InvokeTimeTracker.ShouldContinue.StartTime,
                                         $Resources.InvokeTimeTracker.ShouldContinue.Caption)) { 

                $Current.StartTime = $StartTime 

                $Reports.Push($Resources.InvokeTimeTracker.Information.ProjectedStop -f (ProjectedStop))
            } 
        }
        StopTime {
            if (Assert-StartTime) {
                $Current.StopTime = $StopTime 
            } 
        }
        StartLunch {
            if (-not (Test-StartLunch) -or
                $PSCmdlet.ShouldContinue($Resources.InvokeTimeTracker.ShouldContinue.StartLunch,
                                         $Resources.InvokeTimeTracker.ShouldContinue.Caption)) {

                $Current.StartLunch = $StartLunch

                $Reports.Push($Resources.InvokeTimeTracker.Information.ProjectedLunch -f (ProjectedLunch))
            }
        }
        StopLunch {
            if (Assert-StartLunch) {
                $Current.StopLunch = $StopLunch

                $Reports.Push($Resources.InvokeTimeTracker.Information.LunchLength -f (LunchLength).TotalHours)
            } 
        } 
        Pause {
            if (-not (Test-LastPause) -or
                $PSCmdlet.ShouldContinue($Resources.InvokeTimeTracker.ShouldContinue.LastPause,
                                         $Resources.InvokeTimeTracker.ShouldContinue.Caption)) {

                $OffTime.LastPause = Get-Date 

                $Reports.Push($Resources.InvokeTimeTracker.Information.Pause -f $OffTime.LastPause)
            } 
        }
        Play {
            if (Assert-LastPause) {
                $OffTime.Duration = Duration 

                $Reports.Push($Resources.InvokeTimeTracker.Information.Play -f $OffTime.Duration.TotalHours) 
            }
        }
        WorkDayLength {
            if (-not (Test-WorkDay) -or
                $PSCmdlet.ShouldContinue($Resources.InvokeTimeTracker.ShouldContinue.WorkDay,
                                         $Resources.InvokeTimeTracker.ShouldContinue.Caption)) {

                $Current.WorkDayLength = $WorkDayLength                                                             

                $Reports.Push($Resources.InvokeTimeTracker.Information.SettingWorkDay -f $WorkDayLength.TotalHours)
            } 
        }
        default {
            Write-Warning $Resources.InvokeTimeTracker.Warning.NoParam
        }
    }

    if ($PSBoundParameters.ContainsKey('StopTime') -and
        (Test-StartTime) -and
        $PSCmdlet.ShouldProcess($Path, $Resources.InvokeTimeTracker.ShouldProcess.File)) {

        Write-Verbose ($Resources.InvokeTimeTracker.Verbose.Updating) 

        $timeObj = Get-CurrentTime 

        $timeObj | Export-Csv -Path $Path -Append -Encoding UTF8

        $Reports.Push($Resources.InvokeTimeTracker.Information.Total -f $timeObj.TotalTime)

        Reset-Time 
    } 

    if (-not $Silent) {
        Write-Report
    } 

    if ($PassThru) {
        $TimeObj
    } 
}

