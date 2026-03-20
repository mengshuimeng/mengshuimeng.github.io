$docsRoot = "content/docs"

$dirs = @(
    "$docsRoot/environment",
    "$docsRoot/environment/conda-guide",
    "$docsRoot/environment/wsl-guide",
    "$docsRoot/environment/docker-guide",
    "$docsRoot/environment/git-guide",
    "$docsRoot/environment/venv-tools",

    "$docsRoot/robotics",
    "$docsRoot/robotics/realsense",
    "$docsRoot/robotics/realsense/wsl2-ros2-humble",
    "$docsRoot/robotics/realsense/mount-d435i",
    "$docsRoot/robotics/jetson",
    "$docsRoot/robotics/jetson/jetson-agx-orin",
    "$docsRoot/robotics/jetson/jetson-orin-nano-checklist",
    "$docsRoot/robotics/vision-system",

    "$docsRoot/cv",
    "$docsRoot/cv/yolo-training",
    "$docsRoot/cv/reid-notes",
    "$docsRoot/cv/labelimg",
    "$docsRoot/cv/workflow",

    "$docsRoot/rl-sim",
    "$docsRoot/rl-sim/isaac-lab",
    "$docsRoot/rl-sim/simulation",

    "$docsRoot/fundamentals",
    "$docsRoot/fundamentals/api",
    "$docsRoot/fundamentals/dof",
    "$docsRoot/fundamentals/tensor",

    "$docsRoot/training",
    "$docsRoot/training/vision-training-20251026",
    "$docsRoot/training/vision-training-20251129"
)

function Ensure-Dir {
    param([string]$Path)

    if (!(Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "Created directory: $Path"
    } else {
        Write-Host "Directory exists: $Path"
    }
}

function Ensure-IndexFiles {
    param([string]$DirPath)

    $zhFile = Join-Path $DirPath "_index.zh-cn.md"
    $enFile = Join-Path $DirPath "_index.en.md"

    if (!(Test-Path $zhFile)) {
        @"
---
title: TODO
---

TODO
"@ | Out-File -FilePath $zhFile -Encoding utf8
        Write-Host "Created file: $zhFile"
    } else {
        Write-Host "File exists: $zhFile"
    }

    if (!(Test-Path $enFile)) {
        @"
---
title: TODO
---

TODO
"@ | Out-File -FilePath $enFile -Encoding utf8
        Write-Host "Created file: $enFile"
    } else {
        Write-Host "File exists: $enFile"
    }
}

Ensure-Dir $docsRoot
Ensure-IndexFiles $docsRoot

foreach ($dir in $dirs) {
    Ensure-Dir $dir
    Ensure-IndexFiles $dir
}

Write-Host ""
Write-Host "Done."