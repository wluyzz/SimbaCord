# build.ps1 - compile le launcher C# et build l installeur NSIS
# Usage: .\build.ps1

$ErrorActionPreference = "Stop"

$ROOT       = Split-Path -Parent $MyInvocation.MyCommand.Definition
$SOURCE_DIR = "C:\Users\Princee\Desktop\Simbacord"
$OUTPUT_EXE = "C:\Users\Princee\Desktop\simbacordsetup.exe"

$CSC      = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$MAKENSIS = "$env:LOCALAPPDATA\electron-builder\Cache\nsis\nsis-3.0.4.1\makensis.exe"

$ICON = "$SOURCE_DIR\resources\modules\discord_desktop_core\core\app\images\badges\badge-1.ico"

Write-Host "[1/3] Compile SimbacordLauncher.exe..." -ForegroundColor Cyan
& $CSC /nologo /target:exe /platform:anycpu /optimize+ `
    /out:"$SOURCE_DIR\SimbacordLauncher.exe" `
    /win32icon:"$ICON" `
    "$ROOT\src\SimbacordLauncher.cs"
if ($LASTEXITCODE -ne 0) { throw "csc failed" }

Write-Host "[2/3] Verifie version.txt..." -ForegroundColor Cyan
if (-not (Test-Path "$SOURCE_DIR\version.txt")) {
    throw "version.txt manquant dans $SOURCE_DIR - cree le avec le numero de version (ex: 1.0.0)"
}
$ver = (Get-Content "$SOURCE_DIR\version.txt" -Raw).Trim()
Write-Host "    version actuelle: $ver"

Write-Host "[3/3] Build simbacordsetup.exe..." -ForegroundColor Cyan
if (Test-Path $OUTPUT_EXE) { Remove-Item $OUTPUT_EXE -Force }
& $MAKENSIS "$ROOT\simbacord-setup.nsi"
if ($LASTEXITCODE -ne 0) { throw "makensis failed" }

$size = [math]::Round((Get-Item $OUTPUT_EXE).Length / 1MB, 1)
Write-Host ""
Write-Host "OK -> $OUTPUT_EXE ($size MB)" -ForegroundColor Green
Write-Host "Upload ce fichier dans la nouvelle release GitHub (tag v$ver)."
