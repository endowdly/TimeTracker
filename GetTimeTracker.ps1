function Get-TimeTracker {

    [CmdletBinding(DefaultParameterSetName='TimeTracker')]

    param (
        [Parameter(ParameterSetName='Raw')]
        [Alias('Raw')]
        [switch] $Read,
        
        [Parameter(ParameterSetName='Object')]
        [switch] $AsObject,
        
        [Parameter(ValueFromPipeline)]
        [ValidateScript({ Assert-Path $_ })]
        [string] $Path = $TimeTracker.TrackerPath)
    
    switch ($PSCmdlet.ParameterSetName) {
        Raw { Get-Content $Path -Raw -Encoding UTF8}
        Object { Import-Csv $Path } 
        default { Get-Item $Path }
    } 
}