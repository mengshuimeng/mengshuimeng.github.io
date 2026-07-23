Set-StrictMode -Version Latest

function Resolve-SafeChildPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,

        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        throw 'Relative path must not be empty.'
    }

    if ([IO.Path]::IsPathRooted($RelativePath)) {
        throw "Absolute paths are not allowed: $RelativePath"
    }

    $rootPath = [IO.Path]::GetFullPath($Root).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    $candidate = [IO.Path]::GetFullPath((Join-Path $rootPath $RelativePath))
    $prefix = $rootPath + [IO.Path]::DirectorySeparatorChar

    if (-not $candidate.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escapes configured root: $RelativePath"
    }

    return $candidate
}

function Assert-ManifestProperty {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Entry,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [int]$Index
    )

    $property = $Entry.PSObject.Properties[$Name]
    if ($null -eq $property) {
        throw "Manifest entry $Index is missing required property '$Name'."
    }

    return $property.Value
}

function Read-SyncManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$SourceRoot,

        [Parameter(Mandatory = $true)]
        [string]$RepositoryRoot
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Manifest does not exist: $Path"
    }
    if (-not (Test-Path -LiteralPath $SourceRoot -PathType Container)) {
        throw "Source root does not exist: $SourceRoot"
    }
    if (-not (Test-Path -LiteralPath $RepositoryRoot -PathType Container)) {
        throw "Repository root does not exist: $RepositoryRoot"
    }

    try {
        $manifest = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch {
        throw "Manifest is not valid JSON: $($_.Exception.Message)"
    }

    if ($manifest.version -ne 1) {
        throw "Unsupported manifest version '$($manifest.version)'. Expected version 1."
    }
    if ($null -eq $manifest.entries) {
        throw 'Manifest must contain an entries array.'
    }

    $sourceSet = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $destinationSet = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $contentRoot = Resolve-SafeChildPath -Root $RepositoryRoot -RelativePath 'content'
    $result = New-Object 'System.Collections.Generic.List[object]'
    $index = 0

    foreach ($entry in @($manifest.entries)) {
        $index++
        $source = [string](Assert-ManifestProperty -Entry $entry -Name 'source' -Index $index)
        $destination = [string](Assert-ManifestProperty -Entry $entry -Name 'destination' -Index $index)
        $title = [string](Assert-ManifestProperty -Entry $entry -Name 'title' -Index $index)
        $date = [string](Assert-ManifestProperty -Entry $entry -Name 'date' -Index $index)
        $authors = @(Assert-ManifestProperty -Entry $entry -Name 'authors' -Index $index)
        $tags = @(Assert-ManifestProperty -Entry $entry -Name 'tags' -Index $index)
        $enabled = [bool](Assert-ManifestProperty -Entry $entry -Name 'enabled' -Index $index)
        $delete = [bool](Assert-ManifestProperty -Entry $entry -Name 'delete' -Index $index)

        if ([string]::IsNullOrWhiteSpace($title)) {
            throw "Manifest entry $index has an empty title."
        }
        if ($date -notmatch '^\d{4}-\d{2}-\d{2}$') {
            throw "Manifest entry $index has an invalid date '$date'."
        }
        if ($authors.Count -eq 0 -or $tags.Count -eq 0) {
            throw "Manifest entry $index must contain at least one author and tag."
        }

        $sourcePath = Resolve-SafeChildPath -Root $SourceRoot -RelativePath $source
        $destinationPath = Resolve-SafeChildPath -Root $RepositoryRoot -RelativePath $destination
        $contentPrefix = $contentRoot.TrimEnd(
            [IO.Path]::DirectorySeparatorChar,
            [IO.Path]::AltDirectorySeparatorChar
        ) + [IO.Path]::DirectorySeparatorChar

        if (-not $destinationPath.StartsWith($contentPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Manifest entry $index destination must be below content/: $destination"
        }
        if (-not $sourceSet.Add($sourcePath)) {
            throw "Manifest contains duplicate source: $source"
        }
        if (-not $destinationSet.Add($destinationPath)) {
            throw "Manifest contains duplicate destination: $destination"
        }
        if (-not $delete -and -not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
            throw "Manifest source does not exist: $source"
        }

        $result.Add([pscustomobject][ordered]@{
            SourceRelative      = $source
            SourcePath          = $sourcePath
            DestinationRelative = $destination
            DestinationPath     = $destinationPath
            Title               = $title
            Date                = $date
            Authors             = [string[]]$authors
            Tags                = [string[]]$tags
            Enabled             = $enabled
            Delete              = $delete
        })
    }

    return $result.ToArray()
}

Export-ModuleMember -Function Resolve-SafeChildPath, Read-SyncManifest
