$NodeDir = Join-Path $HOME ".polyinstall\node"
$InstallDir = Join-Path $HOME ".polyinstall\typescript"

# Temporarily patch path context to leverage localized npm engine
$env:PATH = "$NodeDir;" + $env:PATH

Write-Host "[+] Target: TypeScript Package Ecosystem for Windows..." -ForegroundColor Cyan
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Error "[-] Node.js/npm module dependencies missing. Run JavaScript toolkit first."
    Exit 1
}

if (-not (Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir | Out-Null }

Write-Host "[+] Routing global npm installation prefix to sandbox..." -ForegroundColor Cyan
& npm config set prefix "$InstallDir"

Write-Host "[+] Fetching and mounting TypeScript compiler binaries..." -ForegroundColor Cyan
& npm install -g typescript

Write-Host "[+] Adjusting system path parameters..." -ForegroundColor Cyan
$OldPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($OldPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable("PATH", "$InstallDir;$OldPath", "User")
}

Write-Host "[+] TypeScript compiler suite successfully mapped! Restart terminal window." -ForegroundColor Green
