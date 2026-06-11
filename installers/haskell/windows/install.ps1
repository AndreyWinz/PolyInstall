$GhcupVersion = "0.1.30.0"
$ExeFile = "x86_64-mingw64-ghcup.exe"
$Url = "https://downloads.haskell.org/~ghcup/$GhcupVersion/$ExeFile"

$InstallDir = Join-Path $HOME ".polyinstall\haskell"
$BinDir = Join-Path $InstallDir "bin"

if (-not (Test-Path $BinDir)) { New-Item -ItemType Directory -Path $BinDir | Out-Null }

Write-Host "[+] Fetching Standalone Windows GHCup Binary..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $Url -OutFile "$BinDir\ghcup.exe" -UseBasicParsing

# Temporarily inject path container properties for local loop shell tasks
$env:PATH = "$BinDir;" + $env:PATH

Write-Host "[+] Unattended installation of GHC compiler engine..." -ForegroundColor Cyan
& ghcup --no-channel install ghc recommended

Write-Host "[+] Unattended installation of Cabal compilation tool..." -ForegroundColor Cyan
& ghcup --no-channel install cabal recommended

Write-Host "[+] Linking continuous path profiles..." -ForegroundColor Cyan
$OldPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$GhcupPath = Join-Path $HOME ".ghcup\bin"
$CabalPath = Join-Path $HOME ".cabal\bin"

if ($OldPath -notlike "*$GhcupPath*") {
    [Environment]::SetEnvironmentVariable("PATH", "$GhcupPath;$CabalPath;$OldPath", "User")
}

Write-Host "[+] Haskell tool suite entirely mounted! Restart terminal window." -ForegroundColor Green
