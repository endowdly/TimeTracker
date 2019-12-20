@{
    InvalidPath       = 'Invalid Path: {0} does not exits!'
    MandatoryPath     = 'Path to a location.'
    InvalidTime       = 'Stop/resume time entered before start/pause time! Time paradoxes are forbidden!'
    Resetting         = 'Resetting time record for the day!' 

    InvokeTimeTracker = @{

        ShouldContinue = @{
            StartTime  = 'Overwrite the current start time?'
            StartLunch = 'Overwrite the current lunch start time?'
            LastPause  = 'Overwrite the last pause start time?'
            WorkDay    = 'Overwrite the current work day time?'
            Caption    = '' 
        }
        
        ShouldProcess  = @{
            WorkDay = 'Overwrite the current work day time?'
            File    = 'Update time tracker file?'
        }

        Verbose        = @{
            Updating = 'Updating time record'
        }

        Information    = @{
            Pausing        = 'Work day has paused. Use -Play to continue tracking time.'
            ProjectedStop  = 'Projected stop time: {0:HHmm}'
            ProjectedLunch = 'Projected lunch stop time: {0:HHmm}'
            LunchLength    = 'Lunch length: {0:0.0}'
            Pause          = 'Paused at: {0:HHmm}'
            Play           = 'Pause duration length: {0:0.0}'
            SettingWorkDay = 'Setting work day to length of: {0:0.0}'
            Over           = 'Overtime: {0:0.0}'
            Total          = 'Total time: {0:0.0}'
        }

        Error          = @{
            Default = 'You should never see this error!'
        }

        Warning = @{
            NoParam = 'No parameters were given!'
        }

    }

    SetTimeTracker    = @{
        ShouldContinue = @{
            Query   = 'Update default time tracker to {0}?'
            Caption = 'Confirm filepath overwrite'
        }

        Verbose        = @{
            Updating = 'Default time tracker <- {0}'
        }
    }
}