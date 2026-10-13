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
    It 'replaces multiline source front matter without leaking it into the article body' {
        $roots = New-TransformRoots
        $source = Join-Path $roots.SourceRoot 'notes\article.md'
        "---`ntitle: Old source metadata`ndate: 2020-01-01`ntags:`n  - old-source-tag`n---`n`n# Test article`n`nReal article body." | Set-Content -LiteralPath $source -Encoding UTF8
        $result = Convert-SyncDocument -Entry (New-TransformEntry) -SourceRoot $roots.SourceRoot -OutputRoot $roots.OutputRoot -SharedAssetsRoot $roots.SharedAssetsRoot
        $text = Get-Content -LiteralPath $result.IndexPath -Raw -Encoding UTF8
        $text | Should Match 'Real article body\.'
        $text | Should Not Match 'Old source metadata|old-source-tag|2020-01-01'
        $text | Should Not Match '(?m)^# Test article$'
    }

    It 'retains explicitly declared legacy URL aliases' {
        $roots = New-TransformRoots
        Set-Content -LiteralPath (Join-Path $roots.SourceRoot 'notes\article.md') -Value 'Article body' -Encoding UTF8
        $entry = New-TransformEntry
        $entry | Add-Member -MemberType NoteProperty -Name Aliases -Value @('/docs/legacy-note/')
        $result = Convert-SyncDocument -Entry $entry -SourceRoot $roots.SourceRoot -OutputRoot $roots.OutputRoot -SharedAssetsRoot $roots.SharedAssetsRoot
        (Get-Content -LiteralPath $result.IndexPath -Raw -Encoding UTF8) | Should Match 'aliases:\n  - "/docs/legacy-note/"'
    }

    It 'keeps the existing bundle when translated media conflicts with its main page' {
        $roots = New-TransformRoots
        New-Item -ItemType Directory -Path (Join-Path $roots.SourceRoot 'english') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $roots.SourceRoot 'notes\article.md') -Value '![main](diagram.png)' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $roots.SourceRoot 'english\article.md') -Value '![translation](diagram.png)' -Encoding UTF8
        [IO.File]::WriteAllBytes((Join-Path $roots.SourceRoot 'notes\diagram.png'), [byte[]]@(1, 2, 3))
        [IO.File]::WriteAllBytes((Join-Path $roots.SourceRoot 'english\diagram.png'), [byte[]]@(4, 5, 6))
        $entry = New-TransformEntry
        $entry | Add-Member -MemberType NoteProperty -Name Translations -Value @([pscustomobject]@{ SourceRelative = 'english\article.md'; Language = 'en'; Title = 'English article' })
        $bundle = Join-Path $roots.OutputRoot $entry.DestinationRelative
        New-Item -ItemType Directory -Path $bundle -Force | Out-Null
        $oldIndex = Join-Path $bundle 'index.md'
        Set-Content -LiteralPath $oldIndex -Value 'Existing article' -Encoding UTF8
        $before = (Get-FileHash -LiteralPath $oldIndex).Hash
        { Convert-SyncDocument -Entry $entry -SourceRoot $roots.SourceRoot -OutputRoot $roots.OutputRoot -SharedAssetsRoot $roots.SharedAssetsRoot } | Should Throw
        (Get-FileHash -LiteralPath $oldIndex).Hash | Should Be $before
    }

    It 'renders an explicit translation and its local media in the same bundle' {
        $roots = New-TransformRoots
        Set-Content -LiteralPath (Join-Path $roots.SourceRoot 'notes\article.md') -Value '# Test article' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $roots.SourceRoot 'notes\article.en.md') -Value "# English article`n`nEnglish body.`n`n![diagram](diagram.png)" -Encoding UTF8
        [IO.File]::WriteAllBytes((Join-Path $roots.SourceRoot 'notes\diagram.png'), [byte[]]@(1, 2, 3))
        $entry = New-TransformEntry
        $entry | Add-Member -MemberType NoteProperty -Name Translations -Value @([pscustomobject]@{ SourceRelative = 'notes\article.en.md'; Language = 'en'; Title = 'English article' })
        $before = (Get-FileHash -LiteralPath (Join-Path $roots.SourceRoot 'notes\article.en.md')).Hash
        $result = Convert-SyncDocument -Entry $entry -SourceRoot $roots.SourceRoot -OutputRoot $roots.OutputRoot -SharedAssetsRoot $roots.SharedAssetsRoot
        $translation = Join-Path $result.BundlePath 'index.en.md'
        Test-Path -LiteralPath $translation | Should Be $true
        $text = Get-Content -LiteralPath $translation -Raw -Encoding UTF8
        $text | Should Match 'title: "English article"'
        $text | Should Match 'English body\.'
        $text | Should Match '!\[diagram\]\(assets/diagram.png\)'
        Test-Path -LiteralPath (Join-Path $result.BundlePath 'assets\diagram.png') | Should Be $true
        (Get-FileHash -LiteralPath (Join-Path $roots.SourceRoot 'notes\article.en.md')).Hash | Should Be $before
    }

    It 'generates deterministic front matter and removes a matching leading H1' {
        $roots = New-TransformRoots
        $source = Join-Path $roots.SourceRoot 'notes\article.md'
        @(
            '# Test article'
            ''
            'Body text.'
            '> '
        ) | Set-Content -LiteralPath $source -Encoding UTF8
        $entry = New-TransformEntry

        $result = Convert-SyncDocument -Entry $entry -SourceRoot $roots.SourceRoot -OutputRoot $roots.OutputRoot -SharedAssetsRoot $roots.SharedAssetsRoot
        $markdown = Get-Content -LiteralPath $result.IndexPath -Raw -Encoding UTF8

        $markdown | Should Match '^---\ntitle: "Test article"\ndate: 2026-07-23'
        $markdown | Should Match 'authors:\n  - "Mengshuimeng"'
        $markdown | Should Match 'tags:\n  - "robotics"\n  - "test"'
        $markdown | Should Not Match '(?m)^# Test article$'
        $markdown | Should Match 'Body text\.'
        $markdown | Should Match '>\n$'
        $markdown | Should Not Match '(?m)^> +$'
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

    It 'copies and rewrites a linked local video asset' {
        $roots = New-TransformRoots
        $attachmentFolder = -join ([char[]](0x56FE, 0x7247, 0x548C, 0x9644, 0x4EF6))
        $attachmentRoot = Join-Path (Join-Path $roots.SourceRoot 'notes') $attachmentFolder
        New-Item -ItemType Directory -Path $attachmentRoot -Force | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $attachmentRoot 'result video.mp4'), [byte[]](1, 2, 3))
        $source = Join-Path $roots.SourceRoot 'notes\article.md'
        @(
            '# Test article'
            ''
            ('[Result video](' + $attachmentFolder + '/result%20video.mp4)')
        ) | Set-Content -LiteralPath $source -Encoding UTF8
        $entry = New-TransformEntry

        $result = Convert-SyncDocument -Entry $entry -SourceRoot $roots.SourceRoot -OutputRoot $roots.OutputRoot -SharedAssetsRoot $roots.SharedAssetsRoot
        $markdown = Get-Content -LiteralPath $result.IndexPath -Raw -Encoding UTF8

        $markdown | Should Match '\[Result video\]\(assets/result-video\.mp4\)'
        Test-Path -LiteralPath (Join-Path $result.BundlePath 'assets\result-video.mp4') | Should Be $true
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
