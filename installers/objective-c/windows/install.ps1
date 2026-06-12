$Url = "https://github.com/gnustep/tools-windows/releases/download/v1.3/gnustep-core-minimal-x64.zip"
$InstallDir = Join-Path $HOME ".polyinstall\objc"
$TempDir = Join-Path $env:TEMP "PolyInstallObjC"

if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir | Out-Null }

Write-Host "[+] Fetching Standalone Win64 GNUstep Core Runtime..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $Url -OutFile "$TempDir\gnustep.zip" -UseBasicParsing

if (Test-Path $InstallDir) { Remove-Item -Recurse -Force $InstallDir }
New-Item -ItemType Directory -Path $InstallDir | Out-Null

Write-Host "[+] Extracting GNUstep toolchain system objects..." -ForegroundColor Cyan
Expand-Archive -Path "$TempDir\gnustep.zip" -DestinationPath $InstallDir -Force

Write-Host "[+] Mapping environment path directories..." -ForegroundColor Cyan
$OldPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$ObjcBin = Join-Path $InstallDir "bin"

if ($OldPath -notlike "*$ObjcBin*") {
    [Environment]::SetEnvironmentVariable("PATH", "$ObjcBin;$OldPath", "User")
}

Remove-Item -Recurse -Force $TempDir
Write-Host "[+] Objective-C compiler suite deployed completely! Restart shell environment." -ForegroundColor Green
