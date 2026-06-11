# =============================================================================
# PolyInstall — C++ Installer (Windows, PowerShell)
# =============================================================================
# Installs a C++ compiler on Windows by downloading and setting up LLVM/Clang,
# which supports C++ (via clang++) out of the box alongside C.
#
# This is structurally identical to the C installer's Windows variant, with
# two differences:
#   1. The verification step explicitly checks for clang++.exe in addition
#      to clang.exe.
#   2. Both <prefix>\bin entries are confirmed in the final summary.
#
# Usage:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\install.ps1 [-Version <x.y.z>] [-Prefix <install_dir>]
#
# Defaults:
#   -Version   18.1.8
#   -Prefix    $env:USERPROFILE\.local\llvm
# =============================================================================

[CmdletBinding()]
param(
    [string]$Version = "18.1.8",
    [string]$Prefix  = "$env:USERPROFILE\.local\llvm"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Helpers ───────────────────────────────────────────────────────────────────
function Log  { param([string]$Msg) Write-Host "[polyinstall] $Msg" -ForegroundColor Cyan }
function Ok   { param([string]$Msg) Write-Host "[ok] $Msg"          -ForegroundColor Green }
function Warn { param([string]$Msg) Write-Host "[warn] $Msg"        -ForegroundColor Yellow }
function Fail { param([string]$Msg) Write-Error "[error] $Msg"; exit 1 }

# ── Derived variables ─────────────────────────────────────────────────────────
$ZipName      = "LLVM-${Version}-win64.zip"
$ChecksumName = "LLVM-${Version}-win64.zip.sha256"
$BaseUrl      = "https://github.com/llvm/llvm-project/releases/download/llvmorg-${Version}"
$ZipUrl       = "${BaseUrl}/${ZipName}"
$ChecksumUrl  = "${BaseUrl}/${ChecksumName}"

$TempDir      = Join-Path $env:TEMP "polyinstall_cpp_$(Get-Random)"
$ZipPath      = Join-Path $TempDir $ZipName
$ChecksumPath = Join-Path $TempDir $ChecksumName

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

# ── Checksum verification ─────────────────────────────────────────────────────
function Verify-Sha256 {
    param([string]$FilePath, [string]$ChecksumFile)
    Log "Verifying SHA-256 checksum..."
    $raw      = (Get-Content $ChecksumFile -Raw).Trim()
    $expected = ($raw -split '\s+')[0].ToLower()

    if ($expected.Length -ne 64) {
        Fail "Could not parse expected checksum from: $ChecksumFile"
    }

    $actual = (Get-FileHash -Algorithm SHA256 -Path $FilePath).Hash.ToLower()

    if ($expected -ne $actual) {
        Fail "Checksum mismatch!`n  Expected: $expected`n  Got:      $actual"
    }
    Ok "Checksum verified: $actual"
}

# ── Download ──────────────────────────────────────────────────────────────────
Log "Downloading LLVM/Clang ${Version} for Windows x64..."
Download-File $ZipUrl $ZipPath

Log "Downloading checksum..."
Download-File $ChecksumUrl $ChecksumPath

# ── Verify ────────────────────────────────────────────────────────────────────
Verify-Sha256 -FilePath $ZipPath -ChecksumFile $ChecksumPath

# ── Extract ───────────────────────────────────────────────────────────────────
Log "Extracting to ${Prefix}..."

if (Test-Path $Prefix) {
    Log "Destination already exists — removing old installation..."
    Remove-Item -Recurse -Force $Prefix
}
New-Item -ItemType Directory -Path $Prefix | Out-Null

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $Prefix)

# Flatten single nested subdirectory if present
$Inner = Get-ChildItem -Path $Prefix -Directory | Select-Object -First 1
if ($Inner) {
    Get-ChildItem -Path $Inner.FullName | ForEach-Object {
        Move-Item -Path $_.FullName -Destination $Prefix -Force
    }
    Remove-Item -Path $Inner.FullName -Force -ErrorAction SilentlyContinue
}

Ok "Extracted to ${Prefix}"

# ── Verify both compiler binaries ─────────────────────────────────────────────
$ClangExe   = Join-Path $Prefix "bin\clang.exe"
$ClangPPExe = Join-Path $Prefix "bin\clang++.exe"

if (-not (Test-Path $ClangExe))   { Fail "clang.exe not found at: $ClangExe" }
if (-not (Test-Path $ClangPPExe)) { Fail "clang++.exe not found at: $ClangPPExe" }

# ── PATH setup ────────────────────────────────────────────────────────────────
Log "Updating user PATH..."
$BinDir      = Join-Path $Prefix "bin"
$CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "User")

if ($CurrentPath -notlike "*$BinDir*") {
    [Environment]::SetEnvironmentVariable("PATH", "${BinDir};${CurrentPath}", "User")
    Ok "Added to PATH: $BinDir"
} else {
    Log "Already in PATH: $BinDir"
}

$env:PATH = "${BinDir};$env:PATH"

# ── Cleanup ───────────────────────────────────────────────────────────────────
Log "Cleaning up temporary files..."
Remove-Item -Recurse -Force $TempDir

# ── Done ──────────────────────────────────────────────────────────────────────
$ClangVer   = & $ClangExe   --version 2>&1 | Select-Object -First 1
$ClangPPVer = & $ClangPPExe --version 2>&1 | Select-Object -First 1

Ok "LLVM/Clang ${Version} installed successfully to ${Prefix}"
Ok "clang:   $ClangVer"
Ok "clang++: $ClangPPVer"
Write-Host ""
Write-Host "  Verify with: " -NoNewline
Write-Host "clang++ --version" -ForegroundColor Yellow
Write-Host "  Note: Open a new terminal for PATH changes to take full effect."
Write-Host ""
