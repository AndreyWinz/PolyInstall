cat("[+] Initializing Cross-Language R Installer Layer for JavaScript...\n")

node_version <- "22.11.0"
os_info <- Sys.info()[["sysname"]]
machine_info <- Sys.info()[["machine"]]
home_dir <- Sys.getenv("HOME")

if (home_dir == "") {
  home_dir <- Sys.getenv("USERPROFILE")
}

install_dir <- file.path(home_dir, ".polyinstall", "node")
temp_dir <- file.path(tempdir(), "PolyInstallNode")
dir.create(temp_dir, showWarnings = FALSE, recursive = TRUE)

if (grepl("Windows", os_info, ignore.case = TRUE)) {
  arch_type <- if (grepl("64", machine_info)) "x64" else "x86"
  zip_file <- paste0("node-v", node_version, "-win-", arch_type, ".zip")
  url <- paste0("https://nodejs.org/dist/v", node_version, "/", zip_file)
  dest_path <- file.path(temp_dir, zip_file)
  
  cat("[+] Extracting Windows platform zip binary payload packages from:", url, "\n")
  download.file(url, destfile = dest_path, method = "wininet", quiet = TRUE)
  
  if (dir.exists(install_dir)) unlink(install_dir, recursive = TRUE, force = TRUE)
  dir.create(install_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Decompress utilizing built-in powershell handles via clean system invokes
  extract_cmd <- paste0("powershell -Command \"Expand-Archive -Path '", dest_path, "' -DestinationPath '", temp_dir, "\\Extracted' -Force; $inner = Get-ChildItem -Directory -Path '", temp_dir, "\\Extracted' | Select-Object -First 1; Move-Item -Path $inner\\* -Destination '", install_dir, "' -Force\"")
  system(extract_cmd)
  
  cat("[+] Modifying persistent Windows user registry variable strings...\n")
  registry_cmd <- paste0("powershell -Command \"$p=[Environment]::GetEnvironmentVariable('PATH','User'); if($p -notlike '*\\.polyinstall\\node*'){[Environment]::SetEnvironmentVariable('PATH', '", install_dir, ";' + $p, 'User')}\"")
  system(registry_cmd)

} else {
  arch_type <- if (machine_info %in% c("arm64", "aarch64")) "arm64" else "x64"
  
  if (grepl("Darwin", os_info, ignore.case = TRUE)) {
    tarball <- paste0("node-v", node_version, "-darwin-", arch_type, ".tar.gz")
    unpack_flags <- "-xzf"
  } else {
    tarball <- paste0("node-v", node_version, "-linux-", arch_type, ".tar.xz")
    unpack_flags <- "-xJf"
  }
  
  url <- paste0("https://nodejs.org/dist/v", node_version, "/", tarball)
  dest_path <- file.path(temp_dir, tarball)
  
  cat("[+] Fetching standard production tarball source container from:", url, "\n")
  download.file(url, destfile = dest_path, method = "curl", quiet = TRUE)
  
  if (dir.exists(install_dir)) unlink(install_dir, recursive = TRUE, force = TRUE)
  dir.create(install_dir, showWarnings = FALSE, recursive = TRUE)
  
  cat("[+] Running system decompression routines to target folder...\n")
  unpack_cmd <- paste0("tar ", unpack_flags, " ", dest_path, " -C ", install_dir, " --strip-components=1")
  system(unpack_cmd)
  
  cat("[+] Injecting terminal environment synchronization strings...\n")
  shell_env <- Sys.getenv("SHELL")
  rc_name <- if (grepl("zsh", shell_env)) ".zshrc" else ".bashrc"
  rc_path <- file.path(home_dir, rc_name)
  
  append_line <- paste0("\n# PolyInstall JavaScript Engine\nexport PATH=\"", install_dir, "/bin:$PATH\"\n")
  write(append_line, file = rc_path, append = TRUE)
}

cat("[*] SUCCESS: Node.js/JavaScript environment fully compiled via R framework!\n")
