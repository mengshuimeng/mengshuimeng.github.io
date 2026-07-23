$modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'scripts\markdown-sync\SyncMarkdown.psm1'
Import-Module $modulePath -Force

function New-TransformEntry {
    param(
        [string]$SourceRelative = 'notes\article.md',
        [string]$DestinationRelative = 'content\docs\notes\article',
        [string]$Title = 'Test article'
    )

    [pscustomobject][ordered]@{
        SourceRelative      = $SourceRelative
        SourcePath          = ''
        DestinationRelative = $DestinationRelative
        DestinationPath     = ''
        Title               = $Title
        Date                = '2026-07-23'
        Authors             = @('Mengshuimeng')
        Tags                = @('robotics', 'test')
        Enabled             = $true
        Delete              = $false
    }
}

function New-TransformRoots {
    $caseRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
    $sourceRoot = Join-Path $caseRoot 'source'
    $outputRoot = Join-Path $caseRoot 'output'
    $sharedAssetsRoot = Join-Path $sourceRoot 'assets'
    New-Item -ItemType Directory -Path (Join-Path $sourceRoot 'notes') -Force | Out-Null
    New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $sharedAssetsRoot -Force | Out-Null

    [pscustomobject]@{
        SourceRoot       = $sourceRoot
        OutputRoot       = $outputRoot
        SharedAssetsRoot = $sharedAssetsRoot
    }
}

Describe 'Convert-SyncDocument' {
    It 'generates deterministic front matter and removes a matching leading H1' {
        $roots = New-TransformRoots
        $source = Join-Path $roots.SourceRoot 'notes\article.md'
        @(
            '# Test article'
            ''
            'Body text.'
        ) | Set-Content -LiteralPath $source -Encoding UTF8
        $entry = New-TransformEntry

        $result = Convert-SyncDocument -Entry $entry -SourceRoot $roots.SourceRoot -OutputRoot $roots.OutputRoot -SharedAssetsRoot $roots.SharedAssetsRoot
        $markdown = Get-Content -LiteralPath $result.IndexPath -Raw -Encoding UTF8

        $markdown | Should Match '^---\ntitle: "Test article"\ndate: 2026-07-23'
        $markdown | Should Match 'authors:\n  - "Mengshuimeng"'
        $markdown | Should Match 'tags:\n  - "robotics"\n  - "test"'
        $markdown | Should Not Match '(?m)^# Test article$'
        $markdown | Should Match 'Body text\.\n$'
    }

    It 'rewrites a percent-encoded image from the adjacent Chinese attachment directory' {
        $roots = New-TransformRoots
        $attachmentFolder = -join ([char[]](0x56FE, 0x7247, 0x548C, 0x9644, 0x4EF6))
        $attachmentRoot = Join-Path (Join-Path $roots.SourceRoot 'notes') $attachmentFolder
        New-Item -ItemType Directory -Path $attachmentRoot -Force | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $attachmentRoot 'training curve.png'), [byte[]](1, 2, 3))
        $source = Join-Path $roots.SourceRoot 'notes\article.md'
        @(
            '# Test article'
            ''
            ('![Training curve](' + $attachmentFolder + '/training%20curve.png)')
        ) | Set-Content -LiteralPath $source -Encoding UTF8
        $entry = New-TransformEntry

        $result = Convert-SyncDocument -Entry $entry -SourceRoot $roots.SourceRoot -OutputRoot $roots.OutputRoot -SharedAssetsRoot $roots.SharedAssetsRoot
        $markdown = Get-Content -LiteralPath $result.IndexPath -Raw -Encoding UTF8

        $markdown | Should Match '!\[Training curve\]\(assets/training-curve\.png\)'
        Test-Path -LiteralPath (Join-Path $result.BundlePath 'assets\training-curve.png') | Should Be $true
    }

    It 'falls back to the shared asset root by file name' {
        $roots = New-TransformRoots
        [IO.File]::WriteAllBytes((Join-Path $roots.SharedAssetsRoot 'shared diagram.jpg'), [byte[]](4, 5, 6))
        $source = Join-Path $roots.SourceRoot 'notes\article.md'
        @(
            '# Test article'
            ''
            '![Shared](missing-folder/shared%20diagram.jpg)'
        ) | Set-Content -LiteralPath $source -Encoding UTF8
        $entry = New-TransformEntry

        $result = Convert-SyncDocument -Entry $entry -SourceRoot $roots.SourceRoot -OutputRoot $roots.OutputRoot -SharedAssetsRoot $roots.SharedAssetsRoot
        $markdown = Get-Content -LiteralPath $result.IndexPath -Raw -Encoding UTF8

        $markdown | Should Match '!\[Shared\]\(assets/shared-diagram\.jpg\)'
        Test-Path -LiteralPath (Join-Path $result.BundlePath 'assets\shared-diagram.jpg') | Should Be $true
    }

    It 'adds stable suffixes when different images normalize to the same name' {
        $roots = New-TransformRoots
        $first = Join-Path $roots.SourceRoot 'notes\one'
        $second = Join-Path $roots.SourceRoot 'notes\two'
        New-Item -ItemType Directory -Path $first, $second -Force | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $first 'image.png'), [byte[]](1))
        [IO.File]::WriteAllBytes((Join-Path $second 'image.png'), [byte[]](2))
        $source = Join-Path $roots.SourceRoot 'notes\article.md'
        @(
            '# Test article'
            ''
            '![One](one/image.png)'
            '![Two](two/image.png)'
        ) | Set-Content -LiteralPath $source -Encoding UTF8
        $entry = New-TransformEntry

        $result = Convert-SyncDocument -Entry $entry -SourceRoot $roots.SourceRoot -OutputRoot $roots.OutputRoot -SharedAssetsRoot $roots.SharedAssetsRoot
        $markdown = Get-Content -LiteralPath $result.IndexPath -Raw -Encoding UTF8

        $markdown | Should Match '!\[One\]\(assets/image\.png\)'
        $markdown | Should Match '!\[Two\]\(assets/image-2\.png\)'
    }

    It 'preserves image syntax inside code fences and leaves remote images unchanged' {
        $roots = New-TransformRoots
        $source = Join-Path $roots.SourceRoot 'notes\article.md'
        @(
            '# Test article'
            ''
            '```markdown'
            '![Not real](missing.png)'
            '```'
            ''
            '![Remote](https://example.com/image.png)'
        ) | Set-Content -LiteralPath $source -Encoding UTF8
        $entry = New-TransformEntry

        $result = Convert-SyncDocument -Entry $entry -SourceRoot $roots.SourceRoot -OutputRoot $roots.OutputRoot -SharedAssetsRoot $roots.SharedAssetsRoot
        $markdown = Get-Content -LiteralPath $result.IndexPath -Raw -Encoding UTF8

        $markdown | Should Match '!\[Not real\]\(missing\.png\)'
        $markdown | Should Match '!\[Remote\]\(https://example\.com/image\.png\)'
    }

    It 'fails before writing a bundle when a local image is missing' {
        $roots = New-TransformRoots
        $source = Join-Path $roots.SourceRoot 'notes\article.md'
        @(
            '# Test article'
            ''
            '![Missing](missing.png)'
        ) | Set-Content -LiteralPath $source -Encoding UTF8
        $entry = New-TransformEntry

        { Convert-SyncDocument -Entry $entry -SourceRoot $roots.SourceRoot -OutputRoot $roots.OutputRoot -SharedAssetsRoot $roots.SharedAssetsRoot } | Should Throw
        Test-Path -LiteralPath (Join-Path $roots.OutputRoot 'content\docs\notes\article') | Should Be $false
    }
}
