# build.ps1 - compile le launcher C# et build l installeur NSIS
# Usage:
#   .\build.ps1
#   .\build.ps1 -SourceDir "D:\MonSimbacord" -OutputExe "D:\out.exe"
#
# Par defaut, le script detecte automatiquement le dossier source Simbacord :
#   1. Parametre -SourceDir
#   2. Variable d environnement SIMBACORD_SOURCE
#   3. $USERPROFILE\Desktop\Simbacord
# OutputExe fonctionne pareil (parametre, env SIMBACORD_OUTPUT, ou Desktop).

param(
    [string]$SourceDir = "",
    [string]$OutputExe = ""
)

$ErrorActionPreference = "Stop"

$ROOT = Split-Path -Parent $MyInvocation.MyCommand.Definition

# --- Resolution dynamique du dossier source ---
if ([string]::IsNullOrEmpty($SourceDir)) {
    if ($env:SIMBACORD_SOURCE) {
        $SourceDir = $env:SIMBACORD_SOURCE
    } else {
        $SourceDir = Join-Path $env:USERPROFILE "Desktop\Simbacord"
    }
}
if ([string]::IsNullOrEmpty($OutputExe)) {
    if ($env:SIMBACORD_OUTPUT) {
        $OutputExe = $env:SIMBACORD_OUTPUT
    } else {
        $OutputExe = Join-Path $env:USERPROFILE "Desktop\simbacordsetup.exe"
    }
}

if (-not (Test-Path $SourceDir)) {
    throw "Dossier source introuvable : $SourceDir`nAucun Simbacord installe detecte. Installe-le d abord, ou passe -SourceDir."
}

# --- Resolution csc.exe (.NET Framework 4.x compiler) ---
$CSC = $null
$candidates = @(
    "$env:windir\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
    "$env:windir\Microsoft.NET\Framework\v4.0.30319\csc.exe"
)
foreach ($c in $candidates) {
    if (Test-Path $c) { $CSC = $c; break }
}
if (-not $CSC) { throw ".NET Framework 4.x csc.exe introuvable. Installe .NET Framework 4.x." }

# --- Resolution makensis ---
$MAKENSIS = $null
$nsisCandidates = @(
    "$env:LOCALAPPDATA\electron-builder\Cache\nsis\nsis-3.0.4.1\makensis.exe",
    "$env:ProgramFiles\NSIS\makensis.exe",
    "${env:ProgramFiles(x86)}\NSIS\makensis.exe"
)
foreach ($c in $nsisCandidates) {
    if ($c -and (Test-Path $c)) { $MAKENSIS = $c; break }
}
if (-not $MAKENSIS) {
    # fallback : cherche dans le PATH
    $cmd = Get-Command "makensis.exe" -ErrorAction SilentlyContinue
    if ($cmd) { $MAKENSIS = $cmd.Source }
}
if (-not $MAKENSIS) {
    throw "makensis.exe introuvable. Install NSIS depuis https://nsis.sourceforge.io ou via winget : winget install NSIS.NSIS"
}

$ICON = Join-Path $SourceDir "resources\modules\discord_desktop_core\core\app\images\badges\badge-1.ico"
if (-not (Test-Path $ICON)) {
    $altIcon = Join-Path $SourceDir "simbacord.ico"
    if (Test-Path $altIcon) { $ICON = $altIcon } else { $ICON = $null }
}

Write-Host "Configuration :" -ForegroundColor Gray
Write-Host "  Source   : $SourceDir"
Write-Host "  Output   : $OutputExe"
Write-Host "  csc      : $CSC"
Write-Host "  makensis : $MAKENSIS"
Write-Host "  icon     : $(if($ICON){$ICON}else{'(aucun)'})"
Write-Host ""

Write-Host "[1/3] Compile SimbacordLauncher.exe..." -ForegroundColor Cyan
$cscArgs = @(
    "/nologo",
    "/target:exe",
    "/platform:anycpu",
    "/optimize+",
    "/out:$SourceDir\SimbacordLauncher.exe"
)
if ($ICON) { $cscArgs += "/win32icon:$ICON" }
$cscArgs += "$ROOT\src\SimbacordLauncher.cs"
& $CSC $cscArgs
if ($LASTEXITCODE -ne 0) { throw "csc failed" }

Write-Host "[2/3] Verifie version.txt..." -ForegroundColor Cyan
$versionFile = Join-Path $SourceDir "version.txt"
if (-not (Test-Path $versionFile)) {
    throw "version.txt manquant dans $SourceDir - cree le avec le numero de version (ex: 1.0.0)"
}
$ver = (Get-Content $versionFile -Raw).Trim()
Write-Host "    version actuelle: $ver"

Write-Host "[3/3] Build simbacordsetup.exe..." -ForegroundColor Cyan
if (Test-Path $OutputExe) { Remove-Item $OutputExe -Force }
& $MAKENSIS "/DSOURCE_DIR=$SourceDir" "/DOUTPUT_EXE=$OutputExe" "$ROOT\simbacord-setup.nsi"
if ($LASTEXITCODE -ne 0) { throw "makensis failed" }

$size = [math]::Round((Get-Item $OutputExe).Length / 1MB, 1)
Write-Host ""
Write-Host "OK -> $OutputExe ($size MB)" -ForegroundColor Green
Write-Host "Upload ce fichier dans la nouvelle release GitHub (tag v$ver)."
