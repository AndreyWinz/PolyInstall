$NodeVersion = "22.11.0"
$Architecture = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
$ZipFile = "node-v$NodeVersion-win-$Architecture.zip"
$Url = "https://nodejs.org/dist/v$NodeVersion/$ZipFile"

$InstallDir = Join-Path $HOME ".polyinstall\node"
$TempDir = Join-Path $env:TEMP "PolyInstallNode"

if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir | Out-Null }

Write-Host "[+] Fetching Standalone Node.js v$NodeVersion ($Architecture)..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $Url -OutFile "$TempDir\$ZipFile" -UseBasicParsing

if (Test-Path $InstallDir) { Remove-Item -Recurse -Force $InstallDir }
New-Item -ItemType Directory -Path $InstallDir | Out-Null

Write-Host "[+] Unpacking zip distribution modules..." -ForegroundColor Cyan
Expand-Archive -Path "$TempDir\$ZipFile" -DestinationPath "$TempDir\Extracted" -Force

$InnerDir = Get-ChildItem -Directory -Path "$TempDir\Extracted" | Select-Object -First 1
Move-Item -Path "$InnerDir\*" -Destination $InstallDir -Force

Write-Host "[+] Patching individual path registry tables..." -ForegroundColor Cyan
$OldPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($OldPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable("PATH", "$InstallDir;$OldPath", "User")
}

Remove-Item -Recurse -Force $TempDir
Write-Host "[+] JavaScript environment successfully deployed! Restart terminal shell." -ForegroundColor Green
