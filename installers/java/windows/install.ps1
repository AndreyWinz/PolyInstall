$JdkVersion = "21.0.2+13"
$UrlVersion = "jdk-21.0.2%2B13"
$Architecture = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "32" }

if ($Architecture -eq "32") {
    Write-Error "[-] 32-bit production platforms are unsupported by this script build profile."
    Exit 1
}

$ZipFile = "OpenJDK21U-jdk_x64_windows_hotspot_21.0.2_13.zip"
$Url = "https://github.com/adoptium/temurin21-binaries/releases/download/$UrlVersion/$ZipFile"

$InstallDir = Join-Path $HOME ".polyinstall\java"
$TempDir = Join-Path $env:TEMP "PolyInstallJava"

if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir | Out-Null }

Write-Host "[+] Fetching Standalone OpenJDK v$JdkVersion ($Architecture)..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $Url -OutFile "$TempDir\$ZipFile" -UseBasicParsing

if (Test-Path $InstallDir) { Remove-Item -Recurse -Force $InstallDir }
New-Item -ItemType Directory -Path $InstallDir | Out-Null

Write-Host "[+] Unpacking compressed zip runtime clusters..." -ForegroundColor Cyan
Expand-Archive -Path "$TempDir\$ZipFile" -DestinationPath "$TempDir\Extracted" -Force

# Shift the internal root package directory up cleanly to the destination path
$InnerDir = Get-ChildItem -Directory -Path "$TempDir\Extracted" | Select-Object -First 1
Move-Item -Path "$InnerDir\*" -Destination $InstallDir -Force

Write-Host "[+] Adjusting permanent User Registry system profiles..." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable("JAVA_HOME", $InstallDir, "User")

$OldPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$BinPath = Join-Path $InstallDir "bin"
if ($OldPath -notlike "*$BinPath*") {
    [Environment]::SetEnvironmentVariable("PATH", "$BinPath;$OldPath", "User")
}

Remove-Item -Recurse -Force $TempDir
Write-Host "[+] Java environment deployed completely! Please restart active terminal host shells." -ForegroundColor Green
