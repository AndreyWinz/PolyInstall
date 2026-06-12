$VnuVersion = "20.6.30"
$Url = "https://github.com/validator/validator/releases/download/$VnuVersion/vnu-$VnuVersion.jar.zip"

$InstallDir = Join-Path $HOME ".polyinstall\html"
$BinDir = Join-Path $InstallDir "bin"
$TempDir = Join-Path $env:TEMP "PolyInstallHtml"
$NodeDir = Join-Path $HOME ".polyinstall\node"

$env:PATH = "$NodeDir;" + $env:PATH

if (-not (Test-Path $BinDir)) { New-Item -ItemType Directory -Path $BinDir | Out-Null }

Write-Host "[+] Fetching W3C Validator Package Modules..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $Url -OutFile "$TempDir\vnu.zip" -UseBasicParsing
Expand-Archive -Path "$TempDir\vnu.zip" -DestinationPath "$TempDir\Unpacked" -Force
Copy-Item -Path "$TempDir\Unpacked\dist\vnu.jar" -Destination "$InstallDir\vnu.jar" -Force

Write-Host "[+] Generating Windows batch command execution wrapper..." -ForegroundColor Cyan
$BatchContent = @"
@echo off
set JAVA_HOME=%USERPROFILE%\.polyinstall\java
set PATH=%JAVA_HOME%\bin;%PATH%
java -jar "%USERPROFILE%\.polyinstall\html\vnu.jar" %*
"@
Out-File -FilePath "$BinDir\html-validate.bat" -InputObject $BatchContent -Encoding ascii

Write-Host "[+] Allocating standard static web server via local npm handles..." -ForegroundColor Cyan
& npm config set prefix "$InstallDir"
& npm install -g http-server

Write-Host "[+] Appending User System environment paths..." -ForegroundColor Cyan
$OldPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($OldPath -notlike "*$BinDir*") {
    [Environment]::SetEnvironmentVariable("PATH", "$BinDir;$InstallDir;$OldPath", "User")
}

Remove-Item -Recurse -Force $TempDir
Write-Host "[+] HTML5 engineering layout deployed completely! Restart shell." -ForegroundColor Green
