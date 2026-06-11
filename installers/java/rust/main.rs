use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

const JDK_VERSION: &str = "21.0.2+13";
const URL_VERSION: &str = "jdk-21.0.2%2B13";

fn main() {
    println!("[+] Launching Pure Native Rust Installer for OpenJDK...");

    let home_dir = env::var("HOME")
        .or_else(|_| env::var("USERPROFILE"))
        .expect("[-] Failed to resolve current user platform workspace directory.");
    
    let install_dir = Path::new(&home_dir).join(".polyinstall").join("java");
    let mut temp_archive = PathBuf::new();
    let mut url = String::new();

    if cfg!(target_os = "windows") {
        let zip_file = "OpenJDK21U-jdk_x64_windows_hotspot_21.0.2_13.zip";
        url = format!("https://github.com/adoptium/temurin21-binaries/releases/download/{}/{}", URL_VERSION, zip_file);
        temp_archive = Path::new(&env::var("TEMP").unwrap_or_else(|_| "C:\\Windows\\Temp".to_string())).join(zip_file);
    } else if cfg!(target_os = "macos") {
        let arch = if cfg!(target_arch = "aarch64") { "aarch64" } else { "x64" };
        let tarball = format!("OpenJDK21U-jdk_{}_mac_hotspot_21.0.2_13.tar.gz", arch);
        url = format!("https://github.com/adoptium/temurin21-binaries/releases/download/{}/{}", URL_VERSION, tarball);
        temp_archive = Path::new("/tmp").join(tarball);
    } else { // General Linux targets
        let arch = if cfg!(target_arch = "aarch64") { "aarch64" } else { "x64" };
        let tarball = format!("OpenJDK21U-jdk_{}_linux_hotspot_21.0.2_13.tar.gz", arch);
        url = format!("https://github.com/adoptium/temurin21-binaries/releases/download/{}/{}", URL_VERSION, tarball);
        temp_archive = Path::new("/tmp").join(tarball);
    }

    println!("[+] Fetching payload binary platform distribution package from: {}", url);
    if !download_file(&url, temp_archive.to_str().unwrap()) {
        eprintln!("[-] Network infrastructure communication pipe failure encountered.");
        std::process::exit(1);
    }

    println!("[+] Running compression extraction tasks directly to target: {:?}", install_dir);
    if !extract_archive(temp_archive.to_str().unwrap(), install_dir.to_str().unwrap()) {
        eprintln!("[-] Runtime storage mapping unpack failure encountered.");
        std::process::exit(1);
    }

    println!("[+] Committing environment pipeline variable properties...");
    if !update_environment_variables(install_dir.to_str().unwrap()) {
        eprintln!("[-] Environmental path registry modification failed.");
        std::process::exit(1);
    }

    println!("[*] SUCCESS: OpenJDK Environment successfully mapped via Rust binary layer.");
}

fn download_file(url: &str, dest: &str) -> bool {
    let mut cmd = if cfg!(target_os = "windows") {
        let mut c = Command::new("powershell");
        c.args(["-Command", &format!("Invoke-WebRequest -Uri '{}' -OutFile '{}' -UseBasicParsing", url, dest)]);
        c
    } else {
        let mut c = Command::new("curl");
        c.args(["-sSL", "-o", dest, url]);
        c
    };
    cmd.status().map(|s| s.success()).unwrap_or(false)
}

fn extract_archive(archive_path: &str, target_dir: &str) -> bool {
    let _ = fs::remove_dir_all(target_dir);
    fs::create_dir_all(target_dir).expect("[-] Directory space allocation failed.");

    if cfg!(target_os = "windows") {
        let cmd_str = format!(
            "Expand-Archive -Path '{}' -DestinationPath '{}' -Force; \
             $inner = Get-ChildItem -Directory -Path '{}' | Select-Object -First 1; \
             Move-Item -Path \"$inner\\*\" -Destination '{}' -Force", 
            archive_path, archive_path.to_owned() + "_extracted", archive_path.to_owned() + "_extracted", target_dir
        );
        Command::new("powershell").args(["-Command", &cmd_str]).status().map(|s| s.success()).unwrap_or(false)
    } else {
        Command::new("tar")
            .args(["-xzf", archive_path, "-C", target_dir, "--strip-components=1"])
            .status()
            .map(|s| s.success())
            .unwrap_or(false)
    }
}

fn update_environment_variables(install_path: &str) -> bool {
    if cfg!(target_os = "windows") {
        let cmd_str = format!(
            "[Environment]::SetEnvironmentVariable('JAVA_HOME', '{}', 'User'); \
             $p = [Environment]::GetEnvironmentVariable('PATH', 'User'); \
             if($p -notlike '*{}\\bin*'){{ [Environment]::SetEnvironmentVariable('PATH', '{}\\bin;' + $p, 'User') }}", 
            install_path, install_path, install_path
        );
        Command::new("powershell").args(["-Command", &cmd_str]).status().map(|s| s.success()).unwrap_or(false)
    } else {
        let home = env::var("HOME").unwrap_or_default();
        let shell = env::var("SHELL").unwrap_or_default();
        let rc_name = if shell.contains("zsh") { ".zshrc" } else { ".bashrc" };
        let rc_path = Path::new(&home).join(rc_name);

        let mut final_home = install_path.to_string();
        if cfg!(target_os = "macos") {
            let mac_home = Path::new(install_path).join("Contents").join("Home");
            if mac_home.exists() {
                final_home = mac_home.to_str().unwrap().to_string();
            }
        }

        let env_block = format!(
            "\n# PolyInstall Java Profile\nexport JAVA_HOME=\"{}\"\nexport PATH=\"$JAVA_HOME/bin:$PATH\"\n", 
            final_home
        );

        use std::io::Write;
        fs::OpenOptions::new()
            .append(true)
            .create(true)
            .open(rc_path)
            .and_then(|mut f| f.write_all(env_block.as_bytes()))
            .is_ok()
    }
}
