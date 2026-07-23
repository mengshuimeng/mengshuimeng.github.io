[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourceRoot,

    [Parameter(Mandatory = $true)]
    [string]$RepositoryRoot,

    [string]$ManifestPath = (Join-Path $PSScriptRoot 'manifest.json'),

    [string]$SharedAssetsRoot,

    [switch]$DryRun,

    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'SyncMarkdown.psm1') -Force

function Get-SyncFileHash {
    param([Parameter(Mandatory = $true)][string]$Path)

    if ([IO.Path]::GetExtension($Path) -ieq '.md') {
        $text = [IO.File]::ReadAllText($Path).
            Replace("`r`n", "`n").
            Replace("`r", "`n")
        $bytes = (New-Object Text.UTF8Encoding($false)).GetBytes($text)
        $sha256 = [Security.Cryptography.SHA256]::Create()
        try {
            return [BitConverter]::ToString($sha256.ComputeHash($bytes)).Replace('-', '')
        }
        finally {
            $sha256.Dispose()
        }
    }

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Get-DirectoryFingerprint {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return '<missing>'
    }

    $root = [IO.Path]::GetFullPath($Path).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    $lines = foreach ($file in Get-ChildItem -LiteralPath $root -Recurse -File | Sort-Object FullName) {
        $relative = $file.FullName.Substring($root.Length).TrimStart(
            [IO.Path]::DirectorySeparatorChar,
            [IO.Path]::AltDirectorySeparatorChar
        ).Replace('\', '/')
        $hash = Get-SyncFileHash -Path $file.FullName
        "$relative`:$hash"
    }

    return (@($lines) -join "`n")
}

function Copy-DirectoryTransactionally {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    $parent = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    $replacement = Join-Path $parent ('.markdown-sync-replacement-' + [guid]::NewGuid().ToString('N'))

    try {
        Copy-Item -LiteralPath $Source -Destination $replacement -Recurse -Force
        if (Test-Path -LiteralPath $Destination) {
            Remove-Item -LiteralPath $Destination -Recurse -Force
        }
        Move-Item -LiteralPath $replacement -Destination $Destination
    }
    finally {
        if (Test-Path -LiteralPath $replacement) {
            Remove-Item -LiteralPath $replacement -Recurse -Force
        }
    }
}

$resolvedSourceRoot = [IO.Path]::GetFullPath($SourceRoot)
$resolvedRepositoryRoot = [IO.Path]::GetFullPath($RepositoryRoot)
if ([string]::IsNullOrWhiteSpace($SharedAssetsRoot)) {
    $SharedAssetsRoot = Join-Path $resolvedSourceRoot 'assets'
}
$resolvedSharedAssetsRoot = [IO.Path]::GetFullPath($SharedAssetsRoot)

$entries = @(
    Read-SyncManifest `
        -Path $ManifestPath `
        -SourceRoot $resolvedSourceRoot `
        -RepositoryRoot $resolvedRepositoryRoot
)

$stagingRoot = Join-Path ([IO.Path]::GetTempPath()) ('mengshuimeng-markdown-sync-' + [guid]::NewGuid().ToString('N'))
$entryResults = New-Object 'System.Collections.Generic.List[object]'
$managedPaths = New-Object 'System.Collections.Generic.List[string]'
$changed = $false

New-Item -ItemType Directory -Path $stagingRoot -Force | Out-Null

try {
    foreach ($entry in $entries) {
        if (-not $entry.Enabled) {
            continue
        }

        $managedPath = $entry.DestinationRelative.Replace('\', '/')
        $managedPaths.Add($managedPath)

        if ($entry.Delete) {
            $entryChanged = Test-Path -LiteralPath $entry.DestinationPath
            if ($entryChanged) {
                $changed = $true
            }
            $entryResults.Add([pscustomobject][ordered]@{
                Source      = $entry.SourceRelative
                Destination = $managedPath
                Action      = if ($entryChanged) { 'delete' } else { 'none' }
                AssetCount  = 0
            })
            continue
        }

        $rendered = Convert-SyncDocument `
            -Entry $entry `
            -SourceRoot $resolvedSourceRoot `
            -OutputRoot $stagingRoot `
            -SharedAssetsRoot $resolvedSharedAssetsRoot

        $stagedFingerprint = Get-DirectoryFingerprint -Path $rendered.BundlePath
        $destinationFingerprint = Get-DirectoryFingerprint -Path $entry.DestinationPath
        $entryChanged = $stagedFingerprint -cne $destinationFingerprint
        if ($entryChanged) {
            $changed = $true
        }

        $entryResults.Add([pscustomobject][ordered]@{
            Source      = $entry.SourceRelative
            Destination = $managedPath
            Action      = if ($entryChanged) { 'update' } else { 'none' }
            AssetCount  = $rendered.AssetCount
        })
    }

    if (-not $DryRun) {
        foreach ($entry in $entries) {
            if (-not $entry.Enabled) {
                continue
            }

            if ($entry.Delete) {
                if (Test-Path -LiteralPath $entry.DestinationPath) {
                    Remove-Item -LiteralPath $entry.DestinationPath -Recurse -Force
                }
                continue
            }

            $stagedPath = Resolve-SafeChildPath -Root $stagingRoot -RelativePath $entry.DestinationRelative
            if ((Get-DirectoryFingerprint -Path $stagedPath) -cne (Get-DirectoryFingerprint -Path $entry.DestinationPath)) {
                Copy-DirectoryTransactionally -Source $stagedPath -Destination $entry.DestinationPath
            }
        }
    }

    $summary = [pscustomobject][ordered]@{
        Changed      = $changed
        DryRun       = [bool]$DryRun
        Entries      = $entryResults.ToArray()
        ManagedPaths = $managedPaths.ToArray()
    }

    if ($PassThru) {
        return $summary
    }

    Write-Host ("Markdown sync: changed={0}, entries={1}, dryRun={2}" -f $changed, $entryResults.Count, [bool]$DryRun)
}
finally {
    if (Test-Path -LiteralPath $stagingRoot) {
        Remove-Item -LiteralPath $stagingRoot -Recurse -Force
    }
}
