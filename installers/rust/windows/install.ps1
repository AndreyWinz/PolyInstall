$Architecture = if ([Environment]::Is64BitOperatingSystem) { "x86_64" } else { "i686" }
$RustTarget = "$Architecture-pc-windows-msvc"
$Url = "https://static.rust-lang.org/rustup/dist/$RustTarget/rustup-init.exe"

$TempDir = Join-Path $env:TEMP "PolyInstallRust"
if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir | Out-Null }

Write-Host "[+] Fetching Standalone Windows rustup-init Engine ($RustTarget)..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $Url -OutFile "$TempDir\rustup-init.exe" -UseBasicParsing

Write-Host "[+] Processing unattended execution setup..." -ForegroundColor Cyan
& "$TempDir\rustup-init.exe" -y --no-modify-path

Write-Host "[+] Mapping continuous path registers..." -ForegroundColor Cyan
$OldPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$CargoBin = Join-Path $HOME ".cargo\bin"

if ($OldPath -notlike "*$CargoBin*") {
    [Environment]::SetEnvironmentVariable("PATH", "$CargoBin;$OldPath", "User")
}

Remove-Item -Recurse -Force $TempDir
Write-Host "[+] Rust tool suite setup successfully deployed! Restart shell." -ForegroundColor Green
