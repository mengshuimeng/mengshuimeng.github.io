[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourceRoot,

    [Parameter(Mandatory = $true)]
    [string]$RepositoryRoot,

    [string]$ManifestPath = (Join-Path $PSScriptRoot 'manifest.json'),

    [string]$SharedAssetsRoot,

    [string[]]$ManagedPaths = @(),

    [switch]$PlanOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$hugoImage = 'ghcr.io/gohugoio/hugo:v0.164.0'
$baseUrl = 'https://mengshuimeng.github.io/'
$baseReference = 'origin/main'
$pushArguments = @('push', 'origin', 'HEAD:main')

function ConvertTo-ManagedPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $normalized = $Path.Replace('\', '/').Trim('/')
    if (
        [string]::IsNullOrWhiteSpace($normalized) -or
        $normalized -match '(^|/)\.\.(/|$)' -or
        -not $normalized.StartsWith('content/', [StringComparison]::OrdinalIgnoreCase)
    ) {
        throw "Managed path must be below content/: $Path"
    }

    return $normalized
}

function New-PublishPlan {
    param([string[]]$Paths)

    $normalizedPaths = @(
        foreach ($path in @($Paths)) {
            ConvertTo-ManagedPath -Path $path
        }
    )

    return [pscustomobject][ordered]@{
        BaseReference    = $baseReference
        PushRefspec      = 'HEAD:main'
        PushArguments    = $pushArguments
        CloneIsDisposable = $true
        HugoImage        = $hugoImage
        BaseUrl          = $baseUrl
        ManagedPaths     = $normalizedPaths
    }
}

if ($PlanOnly) {
    return New-PublishPlan -Paths $ManagedPaths
}

function Write-RunLog {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Message
    )

    $line = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -LiteralPath $script:LogPath -Value $line -Encoding UTF8
    Write-Host $line
}

function Invoke-ExternalCommand {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [switch]$AllowExitOne
    )

    Write-RunLog ('> {0} {1}' -f $FilePath, ($Arguments -join ' '))
    $output = @(& $FilePath @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    foreach ($line in $output) {
        Write-RunLog ([string]$line)
    }

    if ($exitCode -ne 0 -and -not ($AllowExitOne -and $exitCode -eq 1)) {
        throw "Command failed with exit code ${exitCode}: $FilePath"
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output   = $output
    }
}

function Assert-CommandAvailable {
    param([Parameter(Mandatory = $true)][string]$Name)

    if ($null -eq (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command is unavailable: $Name"
    }
}

function Remove-DisposableClone {
    param(
        [Parameter(Mandatory = $true)][string]$ClonePath,
        [Parameter(Mandatory = $true)][string]$AllowedRoot
    )

    if (-not (Test-Path -LiteralPath $ClonePath)) {
        return
    }

    $resolvedClone = [IO.Path]::GetFullPath($ClonePath)
    $resolvedRoot = [IO.Path]::GetFullPath($AllowedRoot).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    $prefix = $resolvedRoot + [IO.Path]::DirectorySeparatorChar
    if (-not $resolvedClone.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove clone outside state root: $resolvedClone"
    }

    Remove-Item -LiteralPath $resolvedClone -Recurse -Force
}

$resolvedSourceRoot = [IO.Path]::GetFullPath($SourceRoot)
$resolvedRepositoryRoot = [IO.Path]::GetFullPath($RepositoryRoot)
$resolvedManifestPath = [IO.Path]::GetFullPath($ManifestPath)
if ([string]::IsNullOrWhiteSpace($SharedAssetsRoot)) {
    $SharedAssetsRoot = Join-Path $resolvedSourceRoot 'assets'
}
$resolvedSharedAssetsRoot = [IO.Path]::GetFullPath($SharedAssetsRoot)

$stateRoot = Join-Path $env:LOCALAPPDATA 'MengshuimengMarkdownSync'
$logsRoot = Join-Path $stateRoot 'logs'
$workRoot = Join-Path $stateRoot 'work'
New-Item -ItemType Directory -Path $logsRoot, $workRoot -Force | Out-Null

$runId = '{0}-{1}' -f (Get-Date -Format 'yyyyMMdd-HHmmss'), ([guid]::NewGuid().ToString('N').Substring(0, 8))
$script:LogPath = Join-Path $logsRoot ($runId + '.log')
$lastRunPath = Join-Path $stateRoot 'last-run.json'
$cloneRoot = Join-Path $workRoot $runId
$startedAt = Get-Date
$mutex = $null
$mutexAcquired = $false
$result = [ordered]@{
    status     = 'running'
    startedAt  = $startedAt.ToString('o')
    finishedAt = $null
    changed    = $false
    commit     = $null
    log        = $script:LogPath
    error      = $null
}

try {
    $mutex = New-Object Threading.Mutex($false, 'Global\MengshuimengMarkdownSync')
    $mutexAcquired = $mutex.WaitOne(0)
    if (-not $mutexAcquired) {
        throw 'Another Markdown synchronization run is already active.'
    }

    Assert-CommandAvailable -Name 'git'
    Assert-CommandAvailable -Name 'docker'
    if (-not (Test-Path -LiteralPath $resolvedSourceRoot -PathType Container)) {
        throw "Source root does not exist: $resolvedSourceRoot"
    }
    if (-not (Test-Path -LiteralPath $resolvedRepositoryRoot -PathType Container)) {
        throw "Repository root does not exist: $resolvedRepositoryRoot"
    }
    if (-not (Test-Path -LiteralPath $resolvedManifestPath -PathType Leaf)) {
        throw "Manifest does not exist: $resolvedManifestPath"
    }

    Write-RunLog "Starting Markdown publish run $runId"
    $remote = Invoke-ExternalCommand `
        -FilePath 'git' `
        -Arguments @('-C', $resolvedRepositoryRoot, 'remote', 'get-url', 'origin')
    $remoteUrl = ([string]($remote.Output | Select-Object -Last 1)).Trim()
    if ([string]::IsNullOrWhiteSpace($remoteUrl)) {
        throw 'Could not determine the origin remote URL.'
    }

    $null = Invoke-ExternalCommand `
        -FilePath 'git' `
        -Arguments @('clone', '--no-checkout', $remoteUrl, $cloneRoot)
    $null = Invoke-ExternalCommand `
        -FilePath 'git' `
        -Arguments @('-C', $cloneRoot, 'checkout', '--detach', $baseReference)

    $syncArguments = @{
        SourceRoot       = $resolvedSourceRoot
        RepositoryRoot   = $cloneRoot
        ManifestPath     = $resolvedManifestPath
        SharedAssetsRoot = $resolvedSharedAssetsRoot
        PassThru         = $true
    }
    $syncResult = & (Join-Path $PSScriptRoot 'sync-markdown.ps1') @syncArguments
    $normalizedManagedPaths = @(
        foreach ($path in @($syncResult.ManagedPaths)) {
            ConvertTo-ManagedPath -Path ([string]$path)
        }
    )

    $null = Invoke-ExternalCommand `
        -FilePath 'git' `
        -Arguments @('-C', $cloneRoot, 'diff', '--check')

    $mountArgument = 'type=bind,source={0},target=/project' -f $cloneRoot
    $null = Invoke-ExternalCommand `
        -FilePath 'docker' `
        -Arguments @(
            'run',
            '--rm',
            '--user', 'root',
            '--mount', $mountArgument,
            '--workdir', '/project',
            $hugoImage,
            '--gc',
            '--minify',
            '--baseURL', $baseUrl,
            '--destination', '/tmp/site'
        )

    if ($normalizedManagedPaths.Count -gt 0) {
        $stageArguments = @('-C', $cloneRoot, 'add', '--') + $normalizedManagedPaths
        $null = Invoke-ExternalCommand -FilePath 'git' -Arguments $stageArguments
    }

    $stagedDiff = Invoke-ExternalCommand `
        -FilePath 'git' `
        -Arguments @('-C', $cloneRoot, 'diff', '--cached', '--quiet') `
        -AllowExitOne
    if ($stagedDiff.ExitCode -eq 0) {
        $result.status = 'no_changes'
        Write-RunLog 'No managed Markdown changes were detected.'
    }
    else {
        $commitMessage = 'docs: sync Markdown {0}' -f (Get-Date -Format 'yyyy-MM-dd')
        $null = Invoke-ExternalCommand `
            -FilePath 'git' `
            -Arguments @('-C', $cloneRoot, 'commit', '-m', $commitMessage)
        $head = Invoke-ExternalCommand `
            -FilePath 'git' `
            -Arguments @('-C', $cloneRoot, 'rev-parse', 'HEAD')
        $result.commit = ([string]($head.Output | Select-Object -Last 1)).Trim()
        $null = Invoke-ExternalCommand `
            -FilePath 'git' `
            -Arguments (@('-C', $cloneRoot) + $pushArguments)
        $result.changed = $true
        $result.status = 'published'
        Write-RunLog "Published commit $($result.commit)"
    }
}
catch {
    $result.status = 'failed'
    $result.error = $_.Exception.Message
    if ($null -ne $script:LogPath) {
        Write-RunLog ('ERROR: ' + $_.Exception.Message)
    }
    throw
}
finally {
    try {
        Remove-DisposableClone -ClonePath $cloneRoot -AllowedRoot $workRoot
    }
    catch {
        $result.status = 'failed'
        $result.error = $_.Exception.Message
    }

    if ($mutexAcquired -and $null -ne $mutex) {
        $mutex.ReleaseMutex()
    }
    if ($null -ne $mutex) {
        $mutex.Dispose()
    }

    $result.finishedAt = (Get-Date).ToString('o')
    $result | ConvertTo-Json -Depth 5 |
        Set-Content -LiteralPath $lastRunPath -Encoding UTF8
}

[pscustomobject]$result
