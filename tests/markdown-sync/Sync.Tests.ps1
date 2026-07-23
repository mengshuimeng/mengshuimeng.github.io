$repositoryUnderTest = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$syncScript = Join-Path $repositoryUnderTest 'scripts\markdown-sync\sync-markdown.ps1'

function New-SyncFixture {
    $caseRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
    $sourceRoot = Join-Path $caseRoot 'source'
    $repositoryRoot = Join-Path $caseRoot 'repository'
    $manifestPath = Join-Path $caseRoot 'manifest.json'
    New-Item -ItemType Directory -Path (Join-Path $sourceRoot 'notes') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $sourceRoot 'assets') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $repositoryRoot 'content') -Force | Out-Null
    @('# Test article', '', 'Body.') |
        Set-Content -LiteralPath (Join-Path $sourceRoot 'notes\article.md') -Encoding UTF8

    [pscustomobject]@{
        CaseRoot       = $caseRoot
        SourceRoot     = $sourceRoot
        RepositoryRoot = $repositoryRoot
        ManifestPath   = $manifestPath
        Destination    = Join-Path $repositoryRoot 'content\docs\notes\article'
    }
}

function Write-SyncManifest {
    param(
        [Parameter(Mandatory = $true)][object]$Fixture,
        [bool]$Enabled = $true,
        [bool]$Delete = $false,
        [string]$Source = 'notes\article.md'
    )

    [ordered]@{
        version = 1
        entries = @(
            [ordered]@{
                source      = $Source
                destination = 'content\docs\notes\article'
                title       = 'Test article'
                date        = '2026-07-23'
                authors     = @('Mengshuimeng')
                tags        = @('test')
                enabled     = $Enabled
                delete      = $Delete
            }
        )
    } | ConvertTo-Json -Depth 8 |
        Set-Content -LiteralPath $Fixture.ManifestPath -Encoding UTF8
}

function Invoke-TestSync {
    param(
        [Parameter(Mandatory = $true)][object]$Fixture,
        [switch]$DryRun
    )

    & $syncScript `
        -SourceRoot $Fixture.SourceRoot `
        -RepositoryRoot $Fixture.RepositoryRoot `
        -ManifestPath $Fixture.ManifestPath `
        -DryRun:$DryRun `
        -PassThru
}

Describe 'sync-markdown.ps1' {
    It 'validates a dry run and reports changes without writing destinations' {
        $fixture = New-SyncFixture
        Write-SyncManifest -Fixture $fixture

        $result = Invoke-TestSync -Fixture $fixture -DryRun

        $result.Changed | Should Be $true
        $result.Entries.Count | Should Be 1
        Test-Path -LiteralPath $fixture.Destination | Should Be $false
    }

    It 'materializes a whitelisted page bundle' {
        $fixture = New-SyncFixture
        Write-SyncManifest -Fixture $fixture

        $result = Invoke-TestSync -Fixture $fixture

        $result.Changed | Should Be $true
        Test-Path -LiteralPath (Join-Path $fixture.Destination 'index.md') | Should Be $true
        ($result.ManagedPaths -contains 'content/docs/notes/article') | Should Be $true
    }

    It 'is idempotent on a second unchanged run' {
        $fixture = New-SyncFixture
        Write-SyncManifest -Fixture $fixture

        $first = Invoke-TestSync -Fixture $fixture
        $before = (Get-FileHash -LiteralPath (Join-Path $fixture.Destination 'index.md') -Algorithm SHA256).Hash
        $second = Invoke-TestSync -Fixture $fixture
        $after = (Get-FileHash -LiteralPath (Join-Path $fixture.Destination 'index.md') -Algorithm SHA256).Hash

        $first.Changed | Should Be $true
        $second.Changed | Should Be $false
        $after | Should Be $before
    }

    It 'ignores disabled entries' {
        $fixture = New-SyncFixture
        Write-SyncManifest -Fixture $fixture -Enabled $false

        $result = Invoke-TestSync -Fixture $fixture

        $result.Changed | Should Be $false
        $result.Entries.Count | Should Be 0
        Test-Path -LiteralPath $fixture.Destination | Should Be $false
    }

    It 'removes a destination only for an explicit deletion entry' {
        $fixture = New-SyncFixture
        New-Item -ItemType Directory -Path $fixture.Destination -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $fixture.Destination 'index.md') -Value 'old' -Encoding UTF8
        Write-SyncManifest -Fixture $fixture -Delete $true -Source 'notes\missing.md'

        $result = Invoke-TestSync -Fixture $fixture

        $result.Changed | Should Be $true
        Test-Path -LiteralPath $fixture.Destination | Should Be $false
    }
}
