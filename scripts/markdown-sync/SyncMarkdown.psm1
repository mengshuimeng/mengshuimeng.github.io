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

function ConvertTo-YamlDoubleQuoted {
    param([Parameter(Mandatory = $true)][string]$Value)

    return '"' + $Value.Replace('\', '\\').Replace('"', '\"') + '"'
}

function Remove-ExistingFrontMatter {
    param([Parameter(Mandatory = $true)][string]$Markdown)

    if ($Markdown -match '\A---\n.*?\n---(?:\n|\z)') {
        return [regex]::Replace(
            $Markdown,
            '\A---\n.*?\n---(?:\n|\z)',
            '',
            [Text.RegularExpressions.RegexOptions]::Singleline
        )
    }

    return $Markdown
}

function ConvertTo-AssetFileName {
    param([Parameter(Mandatory = $true)][string]$FileName)

    $extension = [IO.Path]::GetExtension($FileName).ToLowerInvariant()
    $baseName = [IO.Path]::GetFileNameWithoutExtension($FileName).ToLowerInvariant()
    $baseName = [regex]::Replace($baseName, '[^a-z0-9]+', '-').Trim('-')
    if ([string]::IsNullOrWhiteSpace($baseName)) {
        $baseName = 'image'
    }
    if ([string]::IsNullOrWhiteSpace($extension)) {
        $extension = '.bin'
    }

    return $baseName + $extension
}

function Test-PathBelowRoot {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Root
    )

    $fullPath = [IO.Path]::GetFullPath($Path)
    $fullRoot = [IO.Path]::GetFullPath($Root).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    $prefix = $fullRoot + [IO.Path]::DirectorySeparatorChar
    return $fullPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
}

function Find-LocalImage {
    param(
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][string]$SourceDirectory,
        [Parameter(Mandatory = $true)][string]$SourceRoot,
        [Parameter(Mandatory = $true)][string]$SharedAssetsRoot
    )

    $decoded = [Uri]::UnescapeDataString($Target.Trim())
    if ($decoded.StartsWith('<') -and $decoded.EndsWith('>')) {
        $decoded = $decoded.Substring(1, $decoded.Length - 2)
    }
    $decoded = $decoded.Replace('/', [IO.Path]::DirectorySeparatorChar)

    if ([IO.Path]::IsPathRooted($decoded) -or $decoded -match '^[a-zA-Z]:') {
        throw "Absolute local image paths are not allowed: $Target"
    }

    $attachmentFolder = -join ([char[]](0x56FE, 0x7247, 0x548C, 0x9644, 0x4EF6))
    $fileName = [IO.Path]::GetFileName($decoded)
    $candidates = @(
        (Join-Path $SourceDirectory $decoded),
        (Join-Path (Join-Path $SourceDirectory $attachmentFolder) $fileName),
        (Join-Path $SharedAssetsRoot $decoded),
        (Join-Path $SharedAssetsRoot $fileName)
    )

    foreach ($candidate in $candidates) {
        $fullCandidate = [IO.Path]::GetFullPath($candidate)
        if (-not (Test-PathBelowRoot -Path $fullCandidate -Root $SourceRoot)) {
            continue
        }
        if (Test-Path -LiteralPath $fullCandidate -PathType Leaf) {
            return $fullCandidate
        }
    }

    throw "Local image could not be resolved: $Target"
}

function Convert-SyncDocument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Entry,

        [Parameter(Mandatory = $true)]
        [string]$SourceRoot,

        [Parameter(Mandatory = $true)]
        [string]$OutputRoot,

        [Parameter(Mandatory = $true)]
        [string]$SharedAssetsRoot
    )

    $sourcePath = Resolve-SafeChildPath -Root $SourceRoot -RelativePath ([string]$Entry.SourceRelative)
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Source document does not exist: $($Entry.SourceRelative)"
    }

    $bundlePath = Resolve-SafeChildPath -Root $OutputRoot -RelativePath ([string]$Entry.DestinationRelative)
    $bundleParent = Split-Path -Parent $bundlePath
    New-Item -ItemType Directory -Path $bundleParent -Force | Out-Null
    $temporaryBundle = Join-Path $bundleParent ('.markdown-sync-' + [guid]::NewGuid().ToString('N'))
    $assetsPath = Join-Path $temporaryBundle 'assets'
    New-Item -ItemType Directory -Path $assetsPath -Force | Out-Null

    try {
        $markdown = Get-Content -LiteralPath $sourcePath -Raw -Encoding UTF8
        $markdown = $markdown.Replace("`r`n", "`n").Replace("`r", "`n")
        $markdown = Remove-ExistingFrontMatter -Markdown $markdown
        $markdown = $markdown.TrimStart("`n")

        $lines = [regex]::Split($markdown, "`n")
        if ($lines.Count -gt 0) {
            $expectedHeading = '# ' + ([string]$Entry.Title).Trim()
            if ($lines[0].Trim() -ceq $expectedHeading) {
                if ($lines.Count -gt 1) {
                    $lines = $lines[1..($lines.Count - 1)]
                }
                else {
                    $lines = @()
                }
                while ($lines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($lines[0])) {
                    if ($lines.Count -eq 1) {
                        $lines = @()
                    }
                    else {
                        $lines = $lines[1..($lines.Count - 1)]
                    }
                }
            }
        }

        $sourceDirectory = Split-Path -Parent $sourcePath
        $sourceToName = New-Object 'System.Collections.Generic.Dictionary[string,string]' ([StringComparer]::OrdinalIgnoreCase)
        $usedNames = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
        $inFence = $false
        $fenceMarker = ''
        $imagePattern = '!\[(?<alt>[^\]]*)\]\((?<target>[^)]+)\)'
        $linkedMediaPattern = '(?<!!)\[(?<alt>[^\]]*)\]\((?<target>[^)]+)\)'

        for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
            $trimmed = $lines[$lineIndex].TrimStart()
            if ($trimmed -match '^(```|~~~)') {
                $marker = $Matches[1]
                if (-not $inFence) {
                    $inFence = $true
                    $fenceMarker = $marker
                }
                elseif ($marker -eq $fenceMarker) {
                    $inFence = $false
                    $fenceMarker = ''
                }
                continue
            }
            if ($inFence) {
                continue
            }

            $lines[$lineIndex] = [regex]::Replace($lines[$lineIndex], $imagePattern, {
                param($match)

                $target = $match.Groups['target'].Value.Trim()
                if (
                    $target -match '^(?i:https?://|data:|//)' -or
                    $target.StartsWith('/')
                ) {
                    return $match.Value
                }

                $resolvedImage = Find-LocalImage `
                    -Target $target `
                    -SourceDirectory $sourceDirectory `
                    -SourceRoot $SourceRoot `
                    -SharedAssetsRoot $SharedAssetsRoot

                if ($sourceToName.ContainsKey($resolvedImage)) {
                    $assetName = $sourceToName[$resolvedImage]
                }
                else {
                    $candidateName = ConvertTo-AssetFileName -FileName ([IO.Path]::GetFileName($resolvedImage))
                    $baseName = [IO.Path]::GetFileNameWithoutExtension($candidateName)
                    $extension = [IO.Path]::GetExtension($candidateName)
                    $assetName = $candidateName
                    $suffix = 2
                    while (-not $usedNames.Add($assetName)) {
                        $assetName = "$baseName-$suffix$extension"
                        $suffix++
                    }
                    $sourceToName[$resolvedImage] = $assetName
                    Copy-Item -LiteralPath $resolvedImage -Destination (Join-Path $assetsPath $assetName)
                }

                return '![' + $match.Groups['alt'].Value + '](assets/' + $assetName + ')'
            })

            $lines[$lineIndex] = [regex]::Replace($lines[$lineIndex], $linkedMediaPattern, {
                param($match)

                $target = $match.Groups['target'].Value.Trim()
                if (
                    $target -match '^(?i:https?://|data:|//|#)' -or
                    $target.StartsWith('/')
                ) {
                    return $match.Value
                }

                $decodedTarget = [Uri]::UnescapeDataString($target)
                $extension = [IO.Path]::GetExtension($decodedTarget).ToLowerInvariant()
                if ($extension -notin @('.mp4', '.webm', '.mov', '.m4v')) {
                    return $match.Value
                }

                $resolvedMedia = Find-LocalImage `
                    -Target $target `
                    -SourceDirectory $sourceDirectory `
                    -SourceRoot $SourceRoot `
                    -SharedAssetsRoot $SharedAssetsRoot

                if ($sourceToName.ContainsKey($resolvedMedia)) {
                    $assetName = $sourceToName[$resolvedMedia]
                }
                else {
                    $candidateName = ConvertTo-AssetFileName -FileName ([IO.Path]::GetFileName($resolvedMedia))
                    $baseName = [IO.Path]::GetFileNameWithoutExtension($candidateName)
                    $assetExtension = [IO.Path]::GetExtension($candidateName)
                    $assetName = $candidateName
                    $suffix = 2
                    while (-not $usedNames.Add($assetName)) {
                        $assetName = "$baseName-$suffix$assetExtension"
                        $suffix++
                    }
                    $sourceToName[$resolvedMedia] = $assetName
                    Copy-Item -LiteralPath $resolvedMedia -Destination (Join-Path $assetsPath $assetName)
                }

                return '[' + $match.Groups['alt'].Value + '](assets/' + $assetName + ')'
            })

            if ($lines[$lineIndex] -match '^\s*>\s+$') {
                $lines[$lineIndex] = $lines[$lineIndex].TrimEnd()
            }
        }

        $frontMatter = New-Object 'System.Collections.Generic.List[string]'
        $frontMatter.Add('---')
        $frontMatter.Add('title: ' + (ConvertTo-YamlDoubleQuoted -Value ([string]$Entry.Title)))
        $frontMatter.Add('date: ' + [string]$Entry.Date)
        $frontMatter.Add('authors:')
        foreach ($author in @($Entry.Authors)) {
            $frontMatter.Add('  - ' + (ConvertTo-YamlDoubleQuoted -Value ([string]$author)))
        }
        $frontMatter.Add('tags:')
        foreach ($tag in @($Entry.Tags)) {
            $frontMatter.Add('  - ' + (ConvertTo-YamlDoubleQuoted -Value ([string]$tag)))
        }
        $frontMatter.Add('---')
        $frontMatter.Add('')

        $outputLines = @($frontMatter.ToArray()) + @($lines)
        $outputMarkdown = (($outputLines -join "`n").TrimEnd("`n") + "`n")
        $indexPath = Join-Path $temporaryBundle 'index.md'
        [IO.File]::WriteAllText($indexPath, $outputMarkdown, (New-Object Text.UTF8Encoding($false)))

        if (Test-Path -LiteralPath $bundlePath) {
            Remove-Item -LiteralPath $bundlePath -Recurse -Force
        }
        Move-Item -LiteralPath $temporaryBundle -Destination $bundlePath

        return [pscustomobject][ordered]@{
            BundlePath = $bundlePath
            IndexPath  = Join-Path $bundlePath 'index.md'
            Markdown   = $outputMarkdown
            AssetCount = $sourceToName.Count
        }
    }
    catch {
        if (Test-Path -LiteralPath $temporaryBundle) {
            Remove-Item -LiteralPath $temporaryBundle -Recurse -Force
        }
        throw
    }
}

Export-ModuleMember -Function Resolve-SafeChildPath, Read-SyncManifest, Convert-SyncDocument
