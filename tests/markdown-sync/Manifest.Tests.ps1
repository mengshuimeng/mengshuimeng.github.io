$modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'scripts\markdown-sync\SyncMarkdown.psm1'
Import-Module $modulePath -Force

function New-TestEntry {
    param(
        [string]$Source = 'notes\article.md',
        [string]$Destination = 'content\docs\notes\article',
        [bool]$Enabled = $true,
        [bool]$Delete = $false
    )

    [ordered]@{
        source      = $Source
        destination = $Destination
        title       = 'Test article'
        date        = '2026-07-23'
        authors     = @('Mengshuimeng')
        tags        = @('test')
        enabled     = $Enabled
        delete      = $Delete
    }
}

function Write-TestManifest {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Entries,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    [ordered]@{
        version = 1
        entries = $Entries
    } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Path -Encoding UTF8
}

Describe 'Resolve-SafeChildPath' {
    BeforeEach {
        $root = Join-Path $TestDrive 'root'
        New-Item -ItemType Directory -Path $root -Force | Out-Null
    }

    It 'resolves a relative child path under the root' {
        $resolved = Resolve-SafeChildPath -Root $root -RelativePath 'one\two.md'
        $resolved | Should Be ([IO.Path]::GetFullPath((Join-Path $root 'one\two.md')))
    }

    It 'rejects an absolute path' {
        { Resolve-SafeChildPath -Root $root -RelativePath 'C:\outside.md' } | Should Throw
    }

    It 'rejects parent traversal' {
        { Resolve-SafeChildPath -Root $root -RelativePath '..\outside.md' } | Should Throw
    }
}

Describe 'Read-SyncManifest' {
    BeforeEach {
        $sourceRoot = Join-Path $TestDrive 'source'
        $repositoryRoot = Join-Path $TestDrive 'repository'
        $manifestPath = Join-Path $TestDrive 'manifest.json'
        New-Item -ItemType Directory -Path (Join-Path $sourceRoot 'notes') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $repositoryRoot 'content') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $sourceRoot 'notes\article.md') -Value '# Article' -Encoding UTF8
    }

    It 'loads a valid manifest and resolves safe paths' {
        Write-TestManifest -Entries @(New-TestEntry) -Path $manifestPath

        $entries = @(Read-SyncManifest -Path $manifestPath -SourceRoot $sourceRoot -RepositoryRoot $repositoryRoot)

        $entries.Count | Should Be 1
        $entries[0].SourcePath | Should Be ([IO.Path]::GetFullPath((Join-Path $sourceRoot 'notes\article.md')))
        $entries[0].DestinationPath | Should Be ([IO.Path]::GetFullPath((Join-Path $repositoryRoot 'content\docs\notes\article')))
    }

    It 'rejects duplicate source paths' {
        Write-TestManifest -Entries @(
            (New-TestEntry),
            (New-TestEntry -Destination 'content\docs\notes\other')
        ) -Path $manifestPath

        { Read-SyncManifest -Path $manifestPath -SourceRoot $sourceRoot -RepositoryRoot $repositoryRoot } | Should Throw
    }

    It 'rejects duplicate destination paths' {
        Set-Content -LiteralPath (Join-Path $sourceRoot 'notes\other.md') -Value '# Other' -Encoding UTF8
        Write-TestManifest -Entries @(
            (New-TestEntry),
            (New-TestEntry -Source 'notes\other.md')
        ) -Path $manifestPath

        { Read-SyncManifest -Path $manifestPath -SourceRoot $sourceRoot -RepositoryRoot $repositoryRoot } | Should Throw
    }

    It 'rejects destinations outside content' {
        Write-TestManifest -Entries @(New-TestEntry -Destination 'scripts\injected') -Path $manifestPath

        { Read-SyncManifest -Path $manifestPath -SourceRoot $sourceRoot -RepositoryRoot $repositoryRoot } | Should Throw
    }

    It 'rejects a missing source unless deletion is explicit' {
        Write-TestManifest -Entries @(New-TestEntry -Source 'notes\missing.md') -Path $manifestPath

        { Read-SyncManifest -Path $manifestPath -SourceRoot $sourceRoot -RepositoryRoot $repositoryRoot } | Should Throw
    }

    It 'allows a missing source only for an explicit deletion entry' {
        Write-TestManifest -Entries @(New-TestEntry -Source 'notes\missing.md' -Delete $true) -Path $manifestPath

        $entries = @(Read-SyncManifest -Path $manifestPath -SourceRoot $sourceRoot -RepositoryRoot $repositoryRoot)

        $entries.Count | Should Be 1
        $entries[0].Delete | Should Be $true
    }
}
