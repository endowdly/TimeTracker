function Set-TimeTracker {
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]  # Yes, it does?

    param (
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName,
                   HelpMessage={ $Resources.MandatoryPath })]
        [ValidateScript({ Assert-Path $_ })]
        [string] $Path,
        
        [switch] $Force)

    $fp = Resolve-Path $Path
    $q = $Resources.SetTimeTracker.ShouldContinue.Query -f $fp
    $c = $Resources.SetTimeTracker.ShouldContinue.Caption

    if ($Force -or $PSCmdlet.ShouldContinue($q, $c)) {
        Write-Verbose ($Resources.SetTimeTracker.Verbose.Updating -f $fp)

        $TimeTracker.TrackerPath = $fp
    }
}
