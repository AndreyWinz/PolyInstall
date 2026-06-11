$GoVersion = "1.26.1"
$Architecture = if ([Environment]::Is64BitOperatingSystem) { "amd64" } else { "386" }
$ZipFile = "go$GoVersion.windows-$Architecture.zip"
$Url = "https://dl.google.com/go/$ZipFile"

$InstallDir = Join-Path $HOME ".polyinstall\go"
$TempDir = Join-Path $env:TEMP "PolyInstallGo"

if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir | Out-Null }

Write-Host "[+] Fetching Go v$GoVersion for Windows ($Architecture)..." -ForegroundColor Cyan

# Fetching matching sha256 checksum string
$ExpectedSha = (Invoke-WebRequest -Uri "$Url.sha256" -UseBasicParsing).Content.Trim()

Write-Host "[+] Downloading archive..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $Url -OutFile "$TempDir\$ZipFile" -UseBasicParsing

Write-Host "[+] Computing cryptographic hash..." -ForegroundColor Cyan
$ActualSha = (Get-FileHash -Path "$TempDir\$ZipFile" -Algorithm SHA256).Hash.ToLower()

if ($ExpectedSha -ne $ActualSha) {
    Write-Error "[-] Cryptographic hash mismatch! Aborting."
    Exit 1
}

if (Test-Path $InstallDir) { Remove-Item -Recurse -Force $InstallDir }
New-Item -ItemType Directory -Path $InstallDir | Out-Null

Write-Host "[+] Extracting archive files..." -ForegroundColor Cyan
Expand-Archive -Path "$TempDir\$ZipFile" -DestinationPath "$TempDir\Extracted" -Force
Move-Item -Path "$TempDir\Extracted\go\*" -Destination $InstallDir -Force

Write-Host "[+] Configuring User Environment Variables..." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable("GOROOT", $InstallDir, "User")

$OldPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$BinPath = Join-Path $InstallDir "bin"
if ($OldPath -notlike "*$BinPath*") {
    $NewPath = "$BinPath;$OldPath"
    [Environment]::SetEnvironmentVariable("PATH", $NewPath, "User")
}

Remove-Item -Recurse -Force $TempDir
Write-Host "[+] Go successfully installed! Please restart your terminal/IDE shell." -ForegroundColor Green
