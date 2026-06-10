# =============================================================================
# PolyInstall — Python Installer (Windows, PowerShell)
# =============================================================================
# Downloads the official CPython embeddable package, verifies its SHA-256
# checksum, extracts it to an install directory, and appends that directory
# to the current user's PATH in the registry.
#
# Usage (from PowerShell, run as normal user):
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\install.ps1 [-Version <x.y.z>] [-Prefix <install_dir>]
#
# Defaults:
#   -Version    3.13.3
#   -Prefix     $env:USERPROFILE\.local\python3
#
# Note: This installer uses the embeddable zip package — a self-contained
# Python distribution that requires no admin rights and no MSI.
# pip is bootstrapped manually via get-pip.py after extraction.
# =============================================================================

[CmdletBinding()]
param(
    [string]$Version = "3.13.3",
    [string]$Prefix  = "$env:USERPROFILE\.local\python3"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Helpers ───────────────────────────────────────────────────────────────────
function Log    { param([string]$Msg) Write-Host "[polyinstall] $Msg" -ForegroundColor Cyan }
function Ok     { param([string]$Msg) Write-Host "[ok] $Msg"          -ForegroundColor Green }
function Fail   { param([string]$Msg) Write-Error "[error] $Msg"; exit 1 }

# ── Derived variables ─────────────────────────────────────────────────────────
# Detect architecture
$Arch = if ([Environment]::Is64BitOperatingSystem) { "amd64" } else { "win32" }
$ZipName   = "python-${Version}-embed-${Arch}.zip"
$BaseUrl   = "https://www.python.org/ftp/python/${Version}"
$ZipUrl    = "${BaseUrl}/${ZipName}"
$Md5SumsUrl = "${BaseUrl}/md5sum.windows.txt"   # Python.org provides MD5 for Windows packages
$GetPipUrl = "https://bootstrap.pypa.io/get-pip.py"

$TempDir   = Join-Path $env:TEMP "polyinstall_python_$(Get-Random)"
$ZipPath   = Join-Path $TempDir $ZipName
$Md5Path   = Join-Path $TempDir "md5sums.txt"
$GetPipPath = Join-Path $TempDir "get-pip.py"

New-Item -ItemType Directory -Path $TempDir | Out-Null

# ── Download helper ───────────────────────────────────────────────────────────
function Download-File {
    param([string]$Url, [string]$Dest)
    Log "Downloading: $Url"
    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($Url, $Dest)
    } catch {
        Fail "Download failed for ${Url}: $_"
    }
}

# ── Checksum verification (MD5) ───────────────────────────────────────────────
# python.org Windows packages ship with MD5 sums, not SHA-256
function Verify-Md5 {
    param([string]$FilePath, [string]$Md5SumsFile, [string]$FileName)

    Log "Verifying MD5 checksum..."
    $expected = $null
    foreach ($line in Get-Content $Md5SumsFile) {
        # Format: <hash>  <filename>
        if ($line -match "^([a-fA-F0-9]{32})\s+.*$([regex]::Escape($FileName))") {
            $expected = $Matches[1].ToLower()
            break
        }
    }
    if (-not $expected) {
        Fail "Could not find checksum for ${FileName} in md5sums file."
    }

    $actual = (Get-FileHash -Algorithm MD5 -Path $FilePath).Hash.ToLower()

    if ($expected -ne $actual) {
        Fail "Checksum mismatch!`n  Expected: $expected`n  Got:      $actual"
    }
    Ok "Checksum verified: $actual"
}

# ── Download ──────────────────────────────────────────────────────────────────
Log "Downloading Python ${Version} (${Arch})..."
Download-File $ZipUrl $ZipPath

Log "Downloading MD5 sums..."
Download-File $Md5SumsUrl $Md5Path

# ── Verify ────────────────────────────────────────────────────────────────────
Verify-Md5 -FilePath $ZipPath -Md5SumsFile $Md5Path -FileName $ZipName

# ── Extract ───────────────────────────────────────────────────────────────────
Log "Extracting to ${Prefix}..."
if (Test-Path $Prefix) {
    Log "Destination already exists, removing old installation..."
    Remove-Item -Recurse -Force $Prefix
}
New-Item -ItemType Directory -Path $Prefix | Out-Null

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $Prefix)
Ok "Extracted to ${Prefix}"

# ── Enable site-packages ──────────────────────────────────────────────────────
# The embeddable package ships with a python3xx._pth file that disables
# site-packages. We need to uncomment the `import site` line to allow pip.
Log "Enabling site-packages..."
$PthFile = Get-ChildItem -Path $Prefix -Filter "python*._pth" | Select-Object -First 1
if ($PthFile) {
    $content = Get-Content $PthFile.FullName
    $content = $content -replace "^#import site", "import site"
    Set-Content -Path $PthFile.FullName -Value $content
    Ok "site-packages enabled in $($PthFile.Name)"
} else {
    Log "Warning: could not find ._pth file; site-packages may not be enabled."
}

# ── Bootstrap pip ─────────────────────────────────────────────────────────────
Log "Downloading get-pip.py..."
Download-File $GetPipUrl $GetPipPath

Log "Installing pip..."
$PythonExe = Join-Path $Prefix "python.exe"
& $PythonExe $GetPipPath --quiet
if ($LASTEXITCODE -ne 0) { Fail "pip installation failed." }
Ok "pip installed."

# ── PATH setup ────────────────────────────────────────────────────────────────
Log "Updating user PATH..."
$ScriptsDir = Join-Path $Prefix "Scripts"
$CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "User")

$DirsToAdd = @($Prefix, $ScriptsDir)
foreach ($dir in $DirsToAdd) {
    if ($CurrentPath -notlike "*$dir*") {
        $CurrentPath = "${dir};${CurrentPath}"
        [Environment]::SetEnvironmentVariable("PATH", $CurrentPath, "User")
        Ok "Added to PATH: $dir"
    } else {
        Log "Already in PATH: $dir"
    }
}

# Also update the current session's PATH so the user can use Python immediately
$env:PATH = ($DirsToAdd -join ";") + ";" + $env:PATH

# ── Cleanup ───────────────────────────────────────────────────────────────────
Log "Cleaning up temporary files..."
Remove-Item -Recurse -Force $TempDir

# ── Done ──────────────────────────────────────────────────────────────────────
Ok "Python ${Version} installed successfully to ${Prefix}"
Write-Host ""
Write-Host "  Verify with: " -NoNewline
Write-Host "python --version" -ForegroundColor Yellow
Write-Host "  Note: Open a new terminal for PATH changes to take full effect."
Write-Host ""
