$ErrorActionPreference = "Stop"

$Owner = "ericyang0709"
$Repo = "release_test"
$AppName = "calculator"
$InstallDir = Join-Path $env:LOCALAPPDATA "Programs\$AppName"
$ExePath = Join-Path $InstallDir "$AppName.exe"

$LatestApi = "https://api.github.com/repos/$Owner/$Repo/releases/latest"

Write-Host "Fetching latest release..."
$Release = Invoke-RestMethod -Uri $LatestApi

$Asset = $Release.assets |
    Where-Object { $_.name -match "\.exe$" } |
    Select-Object -First 1

if (-not $Asset) {
    throw "No .exe asset found in latest release."
}

Write-Host "Latest version: $($Release.tag_name)"
Write-Host "Downloading: $($Asset.name)"

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

Invoke-WebRequest `
    -Uri $Asset.browser_download_url `
    -OutFile $ExePath

Write-Host "Installed to: $ExePath"

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
Write-Host "Done."
Write-Host "Please restart your terminal, then run:"
Write-Host ""
Write-Host "  $AppName"