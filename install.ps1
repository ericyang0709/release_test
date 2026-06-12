$ErrorActionPreference = "Stop"

$Owner = "ericyang0709"
$Repo = "release_test"
$AppName = "mycalculator"

$InstallDir = Join-Path $env:LOCALAPPDATA "Programs\$AppName"
$ExePath = Join-Path $InstallDir "$AppName.exe"
$VersionPath = Join-Path $InstallDir "VERSION"
$UninstallPs1Path = Join-Path $InstallDir "uninstall.ps1"
$UninstallCmdPath = Join-Path $InstallDir "$AppName-uninstall.cmd"

$LatestApi = "https://api.github.com/repos/$Owner/$Repo/releases/latest"

Write-Host "Fetching latest release..."
$Release = Invoke-RestMethod -Uri $LatestApi

$Asset = $Release.assets |
    Where-Object { $_.name -match "\.exe$" } |
    Select-Object -First 1

if (-not $Asset) {
    throw "No .exe asset found in latest release."
}

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

Write-Host "Downloading $($Asset.name)..."
Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $ExePath

Set-Content -Path $VersionPath -Value $Release.tag_name -Encoding UTF8

$UninstallScript = @'
$ErrorActionPreference = "Stop"

$AppName = "mycalculator"
$InstallDir = Join-Path $env:LOCALAPPDATA "Programs\$AppName"

$Process = Get-Process $AppName -ErrorAction SilentlyContinue
if ($Process) {
    Write-Host "$AppName is currently running. Please close it before uninstalling."
    exit 1
}

$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($UserPath) {
    $PathItems = $UserPath -split ";" | Where-Object {
        $_.TrimEnd("\") -ine $InstallDir.TrimEnd("\")
    }

    $NewPath = $PathItems -join ";"
    [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
}

if (Test-Path $InstallDir) {
    Remove-Item -Recurse -Force $InstallDir
}

Write-Host "mycalculator removed."
Write-Host "Please restart your terminal."
'@

Set-Content -Path $UninstallPs1Path -Value $UninstallScript -Encoding UTF8

$UninstallCmd = @"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "$UninstallPs1Path"
"@

Set-Content -Path $UninstallCmdPath -Value $UninstallCmd -Encoding ASCII

$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
$PathItems = $UserPath -split ";" | Where-Object { $_ -ne "" }

$AlreadyInPath = $false
foreach ($Item in $PathItems) {
    if ($Item.TrimEnd("\") -ieq $InstallDir.TrimEnd("\")) {
        $AlreadyInPath = $true
        break
    }
}

if (-not $AlreadyInPath) {
    $NewPath = ($PathItems + $InstallDir) -join ";"
    [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
    Write-Host "Added to User PATH."
}
else {
    Write-Host "PATH already configured."
}

Write-Host ""
Write-Host "Installed $AppName $($Release.tag_name)"
Write-Host "Path: $ExePath"
Write-Host ""
Write-Host "Restart your terminal, then run:"
Write-Host "  $AppName"
Write-Host ""
Write-Host "To uninstall:"
Write-Host "  $AppName-uninstall"
