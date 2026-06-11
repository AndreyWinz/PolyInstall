using System;
using System.IO;
using System.Net.Http;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading.Tasks;

class Program
{
    private const string GhcupVersion = "0.1.30.0";

    static async Task Main(string[] args)
    {
        Console.WriteLine("[+] Booting Cross-Language C# Installer Engine for Haskell...");

        string url = "";
        string homeDir = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        string installDir = Path.Combine(homeDir, ".polyinstall", "haskell");
        string binDir = Path.Combine(installDir, "bin");
        string binPath = Path.Combine(binDir, RuntimeInformation.IsOSPlatform(OSPlatform.Windows) ? "ghcup.exe" : "ghcup");

        Directory.CreateDirectory(binDir);

        if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
        {
            url = $"https://downloads.haskell.org/~ghcup/{GhcupVersion}/x86_64-mingw64-ghcup.exe";
        }
        else if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
        {
            string arch = RuntimeInformation.ProcessArchitecture == Architecture.Arm64 ? "aarch64" : "x86_64";
            url = $"https://downloads.haskell.org/~ghcup/{GhcupVersion}/{arch}-apple-darwin-ghcup";
        }
        else // Linux variants assumed
        {
            string arch = RuntimeInformation.ProcessArchitecture == Architecture.Arm64 ? "aarch64" : "x86_64";
            url = $"https://downloads.haskell.org/~ghcup/{GhcupVersion}/{arch}-linux-ghcup";
        }

        Console.WriteLine($"[+] Pulling raw native core asset container: {url}");
        using (var client = new HttpClient())
        {
            var data = await client.GetByteArrayAsync(url);
            await File.WriteAllBytesAsync(binPath, data);
        }

        if (!RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
        {
            RunProcess("chmod", $"+x \"{binPath}\"");
        }

        Console.WriteLine("[+] Executing non-interactive background build tasks for GHC & Cabal...");
        string oldPath = Environment.GetEnvironmentVariable("PATH") ?? "";
        Environment.SetEnvironmentVariable("PATH", binDir + Path.PathSeparator + oldPath);

        RunProcess(binPath, "--no-channel install ghc recommended");
        RunProcess(binPath, "--no-channel install cabal recommended");

        Console.WriteLine("[+] Writing profile system registrations permanently...");
        UpdatePathVariables(homeDir);

        Console.WriteLine("[*] SUCCESS: Haskell programming setup successfully configured!");
    }

    static void RunProcess(string filename, string arguments)
    {
        var psi = new ProcessStartInfo
        {
            FileName = filename,
            Arguments = arguments,
            UseShellExecute = false,
            CreateNoWindow = true
        };
        using var proc = Process.Start(psi);
        proc?.WaitForExit();
    }

    static void UpdatePathVariables(string homeDir)
    {
        if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
        {
            string oldPath = Environment.GetEnvironmentVariable("PATH", EnvironmentVariableTarget.User) ?? "";
            string ghcupBin = Path.Combine(homeDir, ".ghcup", "bin");
            string cabalBin = Path.Combine(homeDir, ".cabal", "bin");
            if (!oldPath.Contains(".ghcup"))
            {
                Environment.SetEnvironmentVariable("PATH", $"{ghcupBin};{cabalBin};{oldPath}", EnvironmentVariableTarget.User);
            }
        }
        else
        {
            string rcFile = Path.Combine(homeDir, ".bashrc");
            string? shell = Environment.GetEnvironmentVariable("SHELL");
            if (shell != null && shell.Contains("zsh"))
            {
                rcFile = Path.Combine(homeDir, ".zshrc");
            }

            string appendText = "\nexport PATH=\"${HOME}/.ghcup/bin:${HOME}/.cabal/bin:$PATH\"\n";
            File.AppendAllText(rcFile, appendText);
        }
    }
}