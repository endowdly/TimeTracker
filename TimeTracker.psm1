﻿# TimeTracker Module

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]

param(
    [ValidateScript({ (Test-Path $_ -IsValid) -or $( throw "Invalid Path: $_" ) })]
    $Path = (Join-Path $env:USERPROFILE .time))

#region Setup ----------------------------------------------------------------------------------------------------- 
$ModuleRoot = Split-Path $PSScriptRoot -Leaf
$ResourceFile = @{
    BindingVariable = 'Resources'
    BaseDirectory = $PSScriptRoot
    FileName = $ModuleRoot + '.Resources.psd1'
    ErrorAction = 'Stop'
}
$ConfigFile = @{
    BindingVariable = 'Config'
    BaseDirectory = $PSScriptRoot
    FileName = $ModuleRoot + '.Config.psd1'
    ErrorAction = 'Stop'
}

try {
    Import-LocalizedData @ResourceFile 
    Import-LocalizedData @ConfigFile
}
catch {
    Import-LocalizedData @ResourceFile -UICulture en-US

    $Config = @{
        WorkLength = 8.0
        LunchLength = 0.5 
        TrackerPath = $Path
    }
}

#endregion

#region Module Variables ------------------------------------------------------------------------------------------
$OffTime = @{
    Duration  = New-TimeSpan
    LastPause = New-Object DateTime
} 
$Current = @{
    StartTime     = New-Object DateTime
    StopTime      = New-Object DateTime
    StartLunch    = New-Object DateTime
    StopLunch     = New-Object DateTime
    WorkDayLength = New-TimeSpan
}
$Reports = New-Object System.Collections.Queue
$TimeTracker = @{
    Current        = $Current.Clone() 
    OffTime        = $OffTime.Clone()
    WorkDayMinutes = ($Config.WorkLength + $Config.LunchLength) * 60
    LunchHours     = $ConfigFile.LunchLength
    LunchMinutes   = $Config.LunchLength * 60
    TrackerPath    = 
        if (!$Config.TrackerPath) {
            $Path
        }
        else {
            $Config.TrackerPath
        }
} 

Set-Variable TimeTracker -Option ReadOnly

#endregion

#region Module Functions ------------------------------------------------------------------------------------------

function Get-TotalTime {
    $grossTime = $Current.StopTime - $Current.StartTime
    $isNonWorkTime = ((LunchLengthExcess) + $OffTime.Duration) -gt 0
    $nonWorkTime =
        if ($isNonWorkTime) {
            (LunchLengthExcess + $OffTime.Duration)
        }
        else {
            New-TimeSpan
        }

    $grossTime - $nonWorkTime
}
function Get-OverTime {
    $isOver = (TotalTime).TotalMinutes -gt $Current.WorkDayLength.TotalMinutes

    if ($isOver) {
        (TotalTime) - (New-TimeSpan -Minutes $TimeTracker.WorkDayMinutes)
    }
    else {
        New-TimeSpan
    }
} 
function Get-CurrentTime {
    [PSCustomObject]@{
        PSTypeName = 'WorkTime'
        Date       = (Date).ToString('yyyyMMdd')
        StartTime  = $Current.StartTime.ToString('HHmm')
        StopTime   = $Current.StopTime.ToString('HHmm')
        StartLunch = $Current.StartLunch.ToString('HHmm')
        StopLunch  = $Current.StopLunch.ToString('HHmm')
        OffTime    = $OffTime.Duration.TotalHours.ToString('0.0')
        TotalTime  = (TotalTime).TotalHours.ToString('0.0')
        OverTime   = (OverTime).TotalHours.ToString('0.0')
    } 
}

function Get-ProjectedStop { $Current.StartTime.AddHours($Current.WorkDayLength.TotalHours) } 
function Get-ProjectedLunch { $Current.StartLunch.AddMinutes($TimeTracker.LunchMinutes) } 
function Get-LunchLength { $Current.StopLunch - $Current.StartLunch } 
function Get-LunchLengthExcess { (LunchLength) - (New-TimeSpan -Minutes $TimeTracker.LunchMinutes) }
function Get-PauseDuration { (Date) - $OffTime.LastPause }


function Push-Log ($f, $s) {
    $Reports.Enqueue($f -f $s)
}

function Write-Log {
    while ($Reports.Count -gt 0) { 
        Write-Host $Reports.Dequeue()
    } 
}


function Reset-Time {
    Write-Verbose ($Resources.Resetting) 

    $script:Current = $TimeTracker.Current.Clone()
    $script:OffTime = $TimeTracker.OffTime.Clone()
}


#endregion

#region GateKeeper ------------------------------------------------------------------------------------------------


function Test-StartTime { $null -ne $Current.StartTime -and $Current.StartTime -ne $TimeTracker.Current.StartTime }
function Test-StartLunch { $null -ne $Current.StartLunch -and $Current.StartLunch -ne $TimeTracker.Current.StartLunch }
function Test-LastPause { $null -ne $OffTime.LastPause -and $OffTime.LastPause -ne $TimeTracker.OffTime.LastPause }
function Test-WorkDay { $null -ne $Current.WorkDayLength -and $Current.WorkDayLength -ne $TimeTracker.Current.WorkDayLength } 

function Assert-Path ($s) { 
    if (Test-Path $s) {
        $true
    }
    else {
        throw ($Resources.InvalidPath -f $s)
    }
}


function Assert-Time ($b) {
    if ($b) {
        $true
    }
    else {
        $er = New-Object System.Management.Automation.ErrorRecord @(
            [System.InvalidOperationException] $Resources.InvalidTime
            'TimeTracker.TimeParadox'
            [System.Management.Automation.ErrorCategory]::InvalidOperation
            $b
        )

        $PSCmdlet.ThrowTerminatingError($er) 
    }
}
function Assert-StartTime { Assert-Time (Test-StartTime) }
function Assert-StartLunch { Assert-Time (Test-StartLunch) }
function Assert-LastPause { Assert-Time (Test-LastPause) }


#endregion

# --- Source ------------------------------------------------------------------------------------------------------
Join-Path $PSScriptRoot *.ps1 -Resolve | ForEach-Object { . $_ }
