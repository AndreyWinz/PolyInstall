$PhpVersion = "8.3.11"
# Grabbing official x64 Thread Safe build for Windows
$ZipFile = "php-$PhpVersion-Win32-vs16-x64.zip"
$Url = "https://windows.php.net/downloads/releases/$ZipFile"

$InstallDir = Join-Path $HOME ".polyinstall\php"
$TempDir = Join-Path $env:TEMP "PolyInstallPhp"

if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir | Out-Null }

Write-Host "[+] Fetching PHP v$PhpVersion Windows Binary..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $Url -OutFile "$TempDir\$ZipFile" -UseBasicParsing

if (Test-Path $InstallDir) { Remove-Item -Recurse -Force $InstallDir }
New-Item -ItemType Directory -Path $InstallDir | Out-Null

Write-Host "[+] Extracting binaries..." -ForegroundColor Cyan
Expand-Archive -Path "$TempDir\$ZipFile" -DestinationPath $InstallDir -Force

Write-Host "[+] Provisioning base php.ini file..." -ForegroundColor Cyan
Copy-Item -Path (Join-Path $InstallDir "php.ini-development") -Destination (Join-Path $InstallDir "php.ini")

Write-Host "[+] Updating System path registry mapping..." -ForegroundColor Cyan
$OldPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($OldPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable("PATH", "$InstallDir;$OldPath", "User")
}

Remove-Item -Recurse -Force $TempDir
Write-Host "[+] PHP deployment complete. Restart your terminal to verify!" -ForegroundColor Green
