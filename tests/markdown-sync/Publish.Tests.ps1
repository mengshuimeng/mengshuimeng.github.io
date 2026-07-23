$scriptPath = Join-Path $PSScriptRoot '..\..\scripts\markdown-sync\publish-markdown.ps1'

Describe 'publish-markdown.ps1 policy' {
    BeforeEach {
        $source = Join-Path $TestDrive 'source'
        $repository = Join-Path $TestDrive 'repository'
        New-Item -ItemType Directory -Path $source, $repository -Force | Out-Null
    }

    It 'constructs a detached clone publishing plan from origin/main' {
        $plan = & $scriptPath `
            -SourceRoot $source `
            -RepositoryRoot $repository `
            -PlanOnly

        $plan.BaseReference | Should Be 'origin/main'
        $plan.PushRefspec | Should Be 'HEAD:main'
        $plan.CloneIsDisposable | Should Be $true
    }

    It 'pins the official Hugo image and production base URL' {
        $plan = & $scriptPath `
            -SourceRoot $source `
            -RepositoryRoot $repository `
            -PlanOnly

        $plan.HugoImage | Should Be 'ghcr.io/gohugoio/hugo:v0.164.0'
        $plan.BaseUrl | Should Be 'https://mengshuimeng.github.io/'
    }

    It 'never constructs a force push' {
        $plan = & $scriptPath `
            -SourceRoot $source `
            -RepositoryRoot $repository `
            -PlanOnly

        ($plan.PushArguments -contains '--force') | Should Be $false
        ($plan.PushArguments -contains '-f') | Should Be $false
    }

    It 'stages only normalized managed content paths' {
        $managed = @(
            'content\docs\notes\article',
            'content/docs/notes/second'
        )
        $plan = & $scriptPath `
            -SourceRoot $source `
            -RepositoryRoot $repository `
            -ManagedPaths $managed `
            -PlanOnly

        $plan.ManagedPaths.Count | Should Be 2
        $plan.ManagedPaths[0] | Should Be 'content/docs/notes/article'
        $plan.ManagedPaths[1] | Should Be 'content/docs/notes/second'
    }

    It 'rejects a managed path outside content' {
        {
            & $scriptPath `
                -SourceRoot $source `
                -RepositoryRoot $repository `
                -ManagedPaths @('../README.md') `
                -PlanOnly
        } | Should Throw
    }

    It 'records a failed run in last-run.json' {
        $previousLocalAppData = $env:LOCALAPPDATA
        $env:LOCALAPPDATA = Join-Path $TestDrive 'local-app-data'
        try {
            {
                & $scriptPath `
                    -SourceRoot $source `
                    -RepositoryRoot $repository `
                    -ManifestPath (Join-Path $TestDrive 'missing.json')
            } | Should Throw

            $lastRunPath = Join-Path $env:LOCALAPPDATA 'MengshuimengMarkdownSync\last-run.json'
            Test-Path -LiteralPath $lastRunPath | Should Be $true
            $lastRun = Get-Content -LiteralPath $lastRunPath -Raw | ConvertFrom-Json
            $lastRun.status | Should Be 'failed'
            [string]::IsNullOrWhiteSpace([string]$lastRun.error) | Should Be $false
        }
        finally {
            $env:LOCALAPPDATA = $previousLocalAppData
        }
    }

    It 'logs blank lines emitted by external commands' {
        $tokens = $null
        $parseErrors = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile(
            $scriptPath,
            [ref]$tokens,
            [ref]$parseErrors
        )
        $functionAst = $ast.Find({
            param($node)
            $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -eq 'Write-RunLog'
        }, $true)
        . ([scriptblock]::Create($functionAst.Extent.Text))
        $script:LogPath = Join-Path $TestDrive 'publisher.log'

        { Write-RunLog '' } | Should Not Throw
        Test-Path -LiteralPath $script:LogPath | Should Be $true
    }
}
