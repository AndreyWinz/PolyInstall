package main

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
)

const dotnetVersion = "8.0.401"

func main() {
	fmt.Println("[+] Launching Go Native Installer for .NET SDK...")

	var archiveName string
	var installDir string
	var tempArchive string

	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Printf("[-] Failed to read user environment directory: %v\n", err)
		os.Exit(1)
	}

	installDir = filepath.Join(homeDir, ".polyinstall", "dotnet")

	switch runtime.GOOS {
	case "windows":
		archiveName = fmt.Sprintf("dotnet-sdk-%s-win-x64.zip", dotnetVersion)
		tempArchive = filepath.Join(os.Getenv("TEMP"), archiveName)
	case "darwin":
		archType := "x64"
		if runtime.GOARCH == "arm64" {
			archType = "arm64"
		}
		archiveName = fmt.Sprintf("dotnet-sdk-%s-osx-%s.tar.gz", dotnetVersion, archType)
		tempArchive = filepath.Join("/tmp", archiveName)
	default: // Linux system variants
		archType := "x64"
		if runtime.GOARCH == "arm64" {
			archType = "arm64"
		}
		archiveName = fmt.Sprintf("dotnet-sdk-%s-linux-%s.tar.gz", dotnetVersion, archType)
		tempArchive = filepath.Join("/tmp", archiveName)
	}

	url := fmt.Sprintf("https://dotnetcli.azureedge.net/dotnet/Sdk/%s/%s", dotnetVersion, archiveName)

	fmt.Printf("[+] Fetching payload archive asset via download pipeline from: %s\n", url)
	if err := downloadFile(url, tempArchive); err != nil {
		fmt.Printf("[-] Transport failed: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("[+] Extracting binary systems to location target folder: %s\n", installDir)
	if err := extractArchive(tempArchive, installDir); err != nil {
		fmt.Printf("[-] Archive breakdown processing crash: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("[+] Resolving persistent environment variables...")
	if err := updateEnvironment(installDir); err != nil {
		fmt.Printf("[-] Environment variable deployment state failed: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("[*] SUCCESS: .NET Core C# Workspace environment configured cleanly!")
}

func downloadFile(url string, dest string) error {
	var cmd *exec.Cmd
	if runtime.GOOS == "windows" {
		cmd = exec.Command("powershell", "-Command", fmt.Sprintf("Invoke-WebRequest -Uri '%s' -OutFile '%s' -UseBasicParsing", url, dest))
	} else {
		cmd = exec.Command("curl", "-sSL", "-o", dest, url)
	}
	return cmd.Run()
}

func extractArchive(archivePath string, targetDir string) error {
	if runtime.GOOS == "windows" {
		cmdStr := fmt.Sprintf("if(Test-Path '%s'){Remove-Item -Recurse -Force '%s'}; New-Item -ItemType Directory -Path '%s' | Out-Null; Expand-Archive -Path '%s' -DestinationPath '%s' -Force", targetDir, targetDir, targetDir, archivePath, targetDir)
		return exec.Command("powershell", "-Command", cmdStr).Run()
	}
	
	// Unix systems logic setup blocks
	if err := exec.Command("rm", "-rf", targetDir).Run(); err != nil {
		return err
	}
	if err := exec.Command("mkdir", "-p", targetDir).Run(); err != nil {
		return err
	}
	return exec.Command("tar", "-xzf", archivePath, "-C", targetDir).Run()
}

func updateEnvironment(installPath string) error {
	if runtime.GOOS == "windows" {
		cmdStr := fmt.Sprintf("[Environment]::SetEnvironmentVariable('DOTNET_ROOT', '%s', 'User'); $p = [Environment]::GetEnvironmentVariable('PATH', 'User'); if($p -notlike '*%s*'){[Environment]::SetEnvironmentVariable('PATH', '%s;' + $p, 'User')}", installPath, installPath, installPath)
		return exec.Command("powershell", "-Command", cmdStr).Run()
	}

	rcPath := filepath.Join(os.Getenv("HOME"), ".bashrc")
	if shell := os.Getenv("SHELL"); strings.Contains(shell, "zsh") {
		rcPath = filepath.Join(os.Getenv("HOME"), ".zshrc")
	}

	f, err := os.OpenFile(rcPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return err
	}
	defer f.Close()

	envData := fmt.Sprintf("\nexport DOTNET_ROOT=\"%s\"\nexport PATH=\"$DOTNET_ROOT:$PATH\"\n", installPath)
	_, err = io.WriteString(f, envData)
	return err
}
