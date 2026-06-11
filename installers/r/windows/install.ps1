$RVersion = "4.4.2"
$ExeFile = "R-$RVersion-win.exe"
$Url = "https://cran.r-project.org/bin/windows/base/old/$RVersion/$ExeFile"

$InstallDir = Join-Path $HOME ".polyinstall\r"
$TempDir = Join-Path $env:TEMP "PolyInstallR"

if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir | Out-Null }

Write-Host "[+] Fetching R Installer Executable Binary..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $Url -OutFile "$TempDir\$ExeFile" -UseBasicParsing

if (Test-Path $InstallDir) { Remove-Item -Recurse -Force $InstallDir }

Write-Host "[+] Unpacking Windows setup structure silently into userspace..." -ForegroundColor Cyan
# CRAN uses Inno Setup, which allows extracting completely to a target folder without Admin rights
Start-Process -FilePath "$TempDir\$ExeFile" -ArgumentList "/VERYSILENT", "/CURRENTUSER", "/DIR=$InstallDir" -Wait

Write-Host "[+] Registering environment path maps..." -ForegroundColor Cyan
$OldPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$RBinPath = Join-Path $InstallDir "bin\x64"

if ($OldPath -notlike "*$RBinPath*") {
    [Environment]::SetEnvironmentVariable("PATH", "$RBinPath;$OldPath", "User")
}

Remove-Item -Recurse -Force $TempDir
Write-Host "[+] R language environment safely deployed! Restart terminal window." -ForegroundColor Green
