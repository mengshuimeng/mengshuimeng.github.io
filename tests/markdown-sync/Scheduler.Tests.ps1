$scriptPath = Join-Path $PSScriptRoot '..\..\scripts\markdown-sync\install-scheduled-task.ps1'

Describe 'weekly Markdown scheduled task definition' {
    BeforeEach {
        $source = Join-Path $TestDrive 'source'
        $repository = Join-Path $TestDrive 'repository'
        New-Item -ItemType Directory -Path $source, $repository -Force | Out-Null
    }

    It 'runs every Sunday at 22:00' {
        $definition = & $scriptPath `
            -Install `
            -RepositoryRoot $repository `
            -SourceRoot $source `
            -WhatIf `
            -PassThru

        $definition.DayOfWeek | Should Be 'Sunday'
        $definition.At | Should Be '22:00'
    }

    It 'starts missed runs and ignores overlapping instances' {
        $definition = & $scriptPath `
            -Install `
            -RepositoryRoot $repository `
            -SourceRoot $source `
            -WhatIf `
            -PassThru

        $definition.StartWhenAvailable | Should Be $true
        $definition.MultipleInstances | Should Be 'IgnoreNew'
    }

    It 'uses PowerShell 7 with quoted source and repository paths' {
        $definition = & $scriptPath `
            -Install `
            -RepositoryRoot $repository `
            -SourceRoot $source `
            -WhatIf `
            -PassThru

        [IO.Path]::GetFileName($definition.Executable) | Should Be 'pwsh.exe'
        $definition.Arguments | Should Match ([regex]::Escape('"' + $source + '"'))
        $definition.Arguments | Should Match ([regex]::Escape('"' + $repository + '"'))
    }

    It 'uses the current interactive user without storing a password' {
        $definition = & $scriptPath `
            -Install `
            -RepositoryRoot $repository `
            -SourceRoot $source `
            -WhatIf `
            -PassThru

        $definition.LogonType | Should Be 'Interactive'
        $definition.StoresPassword | Should Be $false
        [string]::IsNullOrWhiteSpace([string]$definition.User) | Should Be $false
    }
}
