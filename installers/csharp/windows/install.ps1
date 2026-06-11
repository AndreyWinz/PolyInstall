$DotnetVersion = "8.0.401"
$Architecture = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
$ZipFile = "dotnet-sdk-$DotnetVersion-win-$Architecture.zip"
$Url = "https://dotnetcli.azureedge.net/dotnet/Sdk/$DotnetVersion/$ZipFile"

$InstallDir = Join-Path $HOME ".polyinstall\dotnet"
$TempDir = Join-Path $env:TEMP "PolyInstallDotnet"

if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir | Out-Null }

Write-Host "[+] Fetching Standalone .NET SDK v$DotnetVersion ($Architecture)..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $Url -OutFile "$TempDir\$ZipFile" -UseBasicParsing

if (Test-Path $InstallDir) { Remove-Item -Recurse -Force $InstallDir }
New-Item -ItemType Directory -Path $InstallDir | Out-Null

Write-Host "[+] Extracting .NET Framework binaries..." -ForegroundColor Cyan
Expand-Archive -Path "$TempDir\$ZipFile" -DestinationPath $InstallDir -Force

Write-Host "[+] Configuring User Level Environment Registries..." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable("DOTNET_ROOT", $InstallDir, "User")

$OldPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($OldPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable("PATH", "$InstallDir;$OldPath", "User")
}

Remove-Item -Recurse -Force $TempDir
Write-Host "[+] .NET C# development sdk environment successfully created! Please restart your active shell." -ForegroundColor Green
