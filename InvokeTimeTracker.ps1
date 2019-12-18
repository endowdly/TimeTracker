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

        Push-Log $Resources.InvokeTimeTracker.Information.SettingWorkDay $WorkDayLength.TotalHours 
    } 

    switch ($PSBoundParameters.Keys) {
        StartTime {
            if (-not (Test-StartTime) -or
                $PSCmdlet.ShouldContinue($Resources.InvokeTimeTracker.ShouldContinue.StartTime,
                                         $Resources.InvokeTimeTracker.ShouldContinue.Caption)) { 

                $Current.StartTime = $StartTime 

                Push-Log $Resources.InvokeTimeTracker.Information.ProjectedStop (ProjectedStop)
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

                Push-Log $Resources.InvokeTimeTracker.Information.ProjectedLunch (ProjectedLunch)
            }
        }
        StopLunch {
            if (Assert-StartLunch) {
                $Current.StopLunch = $StopLunch

                Push-Log $Resources.InvokeTimeTracker.Information.LunchLength (LunchLength).TotalHours
            } 
        } 
        Pause {
            if (-not (Test-LastPause) -or
                $PSCmdlet.ShouldContinue($Resources.InvokeTimeTracker.ShouldContinue.LastPause,
                                         $Resources.InvokeTimeTracker.ShouldContinue.Caption)) {

                $OffTime.LastPause = Get-Date 

                Push-Log $Resources.InvokeTimeTracker.Information.Pause $OffTime.LastPause
            } 
        }
        Play {
            if (Assert-LastPause) {
                $OffTime.Duration = Duration 

                Push-Log $Resources.InvokeTimeTracker.Information.Play $OffTime.Duration.TotalHours
            }
        }
        WorkDayLength {
            if (-not (Test-WorkDay) -or
                $PSCmdlet.ShouldContinue($Resources.InvokeTimeTracker.ShouldContinue.WorkDay,
                                         $Resources.InvokeTimeTracker.ShouldContinue.Caption)) {

                $Current.WorkDayLength = $WorkDayLength                                                             

                Push-Log $Resources.InvokeTimeTracker.Information.SettingWorkDay $WorkDayLength.TotalHours
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

        Push-Log $Resources.InvokeTimeTracker.Information.Total $timeObj.TotalTime

        if (($timeObj.OverTime -as [double]) -gt 0.0) {
            Push-Log $Resources.InvokeTimeTracker.Information.Over $timeObj.OverTime
        }

        Reset-Time 
    } 

    if (-not $Silent) {
        Write-Log
    } 

    if ($PassThru) {
        $TimeObj
    } 
}

