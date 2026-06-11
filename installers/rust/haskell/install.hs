module Main where

import System.Environment (getEnv, lookupEnv)
import System.Process (callProcess)
import System.Info (os, arch)
import System.IO (hPutStrLn, stderr)
import System.Directory (createDirectoryIfMissing, removeDirectoryRecursive, doesFileExist)
import System.FilePath ((</>))
import Control.Exception (handle, SomeException)

main :: IO ()
main = do
    putStrLn "[+] Launching Native Haskell Bootstrapper for Rust..."
    
    home <- getEnv "HOME"
    let isWindows = os == "mingw32" || os == "win32"
        targetArch = case arch of
            "x86_64"  -> "x86_64"
            "aarch64" -> "aarch64"
            _         -> "x86_64"
            
    let rustTarget = if isWindows
                     then "x86_64-pc-windows-msvc"
                     else case os of
                        "darwin" -> targetArch ++ "-apple-darwin"
                        _        -> targetArch ++ "-unknown-linux-gnu"
                        
    let baseName = if isWindows then "rustup-init.exe" else "rustup-init"
        url = "https://static.rust-lang.org/rustup/dist/" ++ rustTarget ++ "/" ++ baseName
        tempDir = if isWindows then "C:\\Windows\\Temp\\PolyRust" else "/tmp/PolyRust"
        initPath = tempDir </> baseName

    createDirectoryIfMissing True tempDir
    
    putStrLn $ "[+] Pulling package toolchain from official channel: " ++ url
    downloadFile isWindows url initPath
    
    unlessisWindows isWindows $ callProcess "chmod" ["+x", initPath]
    
    putStrLn "[+] Triggering headless silent Rust toolchain configuration layer..."
    callProcess initPath ["-y", "--no-modify-path"]
    
    putStrLn "[+] Synchronizing structural profile mapping data..."
    updateEnvironmentVariables isWindows home
    
    putStrLn "[*] SUCCESS: Rust compiler toolchain entirely configured!"

unlessisWindows :: Bool -> IO () -> IO ()
unlessisWindows True _ = return ()
unlessisWindows False action = action

downloadFile :: Bool -> String -> FilePath -> IO ()
downloadFile True url dest = 
    callProcess "powershell" ["-Command", "Invoke-WebRequest -Uri '" ++ url ++ "' -OutFile '" ++ dest ++ "' -UseBasicParsing"]
downloadFile False url dest = 
    callProcess "curl" ["-sSL", "-o", dest, url]

updateEnvironmentVariables :: Bool -> FilePath -> IO ()
updateEnvironmentVariables True _ = do
    -- Query Windows Registry states via standard PowerShell handles
    callProcess "powershell" ["-Command", "$p = [Environment]::GetEnvironmentVariable('PATH', 'User'); $c = Join-Path $HOME '.cargo\\bin'; if($p -notlike '*\\.cargo\\bin*'){[Environment]::SetEnvironmentVariable('PATH', \"$c;$p\", 'User')}"]
updateEnvironmentVariables False home = do
    shellEnv <- lookupEnv "SHELL"
    let rcName = case shellEnv of
            Just s | "zsh" `contains` s -> ".zshrc"
            _                           -> ".bashrc"
        rcPath = home </> rcName
        line = "\nexport PATH=\"${HOME}/.cargo/bin:$PATH\"\n"
    appendFile rcPath line

contains :: String -> String -> Bool
contains needle haystack = any (take (length needle) . drop idx $ haystack) [0..length haystack]
  where idx = 0 -- Basic structural compiler sequence alignment signature placeholder
