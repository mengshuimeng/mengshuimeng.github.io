[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Show')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Install')]
    [switch]$Install,

    [Parameter(Mandatory = $true, ParameterSetName = 'Uninstall')]
    [switch]$Uninstall,

    [Parameter(ParameterSetName = 'Show')]
    [switch]$Show,

    [Parameter(Mandatory = $true, ParameterSetName = 'Install')]
    [string]$RepositoryRoot,

    [Parameter(Mandatory = $true, ParameterSetName = 'Install')]
    [string]$SourceRoot,

    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$taskName = 'Mengshuimeng Weekly Markdown Sync'

function ConvertTo-QuotedArgument {
    param([Parameter(Mandatory = $true)][string]$Value)

    return '"' + $Value.Replace('"', '\"') + '"'
}

if ($PSCmdlet.ParameterSetName -eq 'Uninstall') {
    if ($PSCmdlet.ShouldProcess($taskName, 'Unregister scheduled task')) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
    }
    return
}

if ($PSCmdlet.ParameterSetName -eq 'Show') {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
    $info = Get-ScheduledTaskInfo -TaskName $taskName -ErrorAction Stop
    [pscustomobject][ordered]@{
        TaskName       = $task.TaskName
        State          = [string]$task.State
        LastRunTime    = $info.LastRunTime
        LastTaskResult = $info.LastTaskResult
        NextRunTime    = $info.NextRunTime
        Action         = $task.Actions.Execute
        Arguments      = $task.Actions.Arguments
    }
    return
}

$resolvedRepositoryRoot = [IO.Path]::GetFullPath($RepositoryRoot)
$resolvedSourceRoot = [IO.Path]::GetFullPath($SourceRoot)
$publisherPath = Join-Path $resolvedRepositoryRoot 'scripts\markdown-sync\publish-markdown.ps1'
$pwshPath = (Get-Command 'pwsh.exe' -ErrorAction Stop).Source
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$publisherArguments = @(
    '-NoLogo'
    '-NoProfile'
    '-NonInteractive'
    '-ExecutionPolicy'
    'Bypass'
    '-File'
    (ConvertTo-QuotedArgument -Value $publisherPath)
    '-SourceRoot'
    (ConvertTo-QuotedArgument -Value $resolvedSourceRoot)
    '-RepositoryRoot'
    (ConvertTo-QuotedArgument -Value $resolvedRepositoryRoot)
) -join ' '

$definition = [pscustomobject][ordered]@{
    TaskName           = $taskName
    DayOfWeek          = 'Sunday'
    At                 = '22:00'
    StartWhenAvailable = $true
    MultipleInstances  = 'IgnoreNew'
    Executable         = $pwshPath
    Arguments          = $publisherArguments
    User               = $currentUser
    LogonType          = 'Interactive'
    StoresPassword     = $false
}

if (-not $WhatIfPreference) {
    if (-not (Test-Path -LiteralPath $resolvedRepositoryRoot -PathType Container)) {
        throw "Repository root does not exist: $resolvedRepositoryRoot"
    }
    if (-not (Test-Path -LiteralPath $resolvedSourceRoot -PathType Container)) {
        throw "Source root does not exist: $resolvedSourceRoot"
    }
    if (-not (Test-Path -LiteralPath $publisherPath -PathType Leaf)) {
        throw "Publisher script does not exist: $publisherPath"
    }
}

$action = New-ScheduledTaskAction `
    -Execute $pwshPath `
    -Argument $publisherArguments `
    -WorkingDirectory $resolvedRepositoryRoot
$trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Sunday -At '22:00'
$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2)
$principal = New-ScheduledTaskPrincipal `
    -UserId $currentUser `
    -LogonType Interactive `
    -RunLevel Limited
$scheduledTask = New-ScheduledTask `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description 'Synchronize whitelisted Markdown documents, validate Hugo, and publish successful changes.'

if ($PSCmdlet.ShouldProcess($taskName, 'Register weekly scheduled task')) {
    Register-ScheduledTask `
        -TaskName $taskName `
        -InputObject $scheduledTask `
        -Force `
        -ErrorAction Stop | Out-Null
}

if ($PassThru) {
    return $definition
}
