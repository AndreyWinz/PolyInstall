#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "installer.h"

// System wrapper execution matching platform APIs
int download_file(const char *url, const char *dest) {
    char cmd[1024];
#if defined(_WIN32)
    snprintf(cmd, sizeof(cmd), "powershell -Command \"Invoke-WebRequest -Uri '%s' -OutFile '%s' -UseBasicParsing\"", url, dest);
#else
    snprintf(cmd, sizeof(cmd), "curl -sSL -o \"%s\" \"%s\"", dest, url);
#endif
    return system(cmd);
}

int extract_archive(const char *archive_path, const char *target_dir) {
    char cmd[1024];
#if defined(_WIN32)
    snprintf(cmd, sizeof(cmd), "powershell -Command \"if(Test-Path '%s'){Remove-Item -Recurse -Force '%s'}; New-Item -ItemType Directory -Path '%s' | Out-Null; Expand-Archive -Path '%s' -DestinationPath '%s\\..\\TempExtract' -Force; Move-Item -Path '%s\\..\\TempExtract\\go\\*' -Destination '%s'; Remove-Item -Recurse '%s\\..\\TempExtract'\"", 
             target_dir, target_dir, target_dir, archive_path, target_dir, target_dir, target_dir, target_dir);
#else
    snprintf(cmd, sizeof(cmd), "rm -rf \"%s\" && mkdir -p \"%s\" && tar -C \"%s\" --strip-components=1 -xzf \"%s\"", 
             target_dir, target_dir, target_dir, archive_path);
#endif
    return system(cmd);
}

int update_environment(const char *install_path) {
#if defined(_WIN32)
    char cmd[2048];
    snprintf(cmd, sizeof(cmd), 
             "powershell -Command \"[Environment]::SetEnvironmentVariable('GOROOT', '%s', 'User'); "
             "$p = [Environment]::GetEnvironmentVariable('PATH', 'User'); "
             "if ($p -notlike '*%s\\bin*') { [Environment]::SetEnvironmentVariable('PATH', '%s\\bin;' + $p, 'User') }\"", 
             install_path, install_path, install_path);
    return system(cmd);
#else
    char rc_path[512];
    snprintf(rc_path, sizeof(rc_path), "%s/.bashrc", getenv("HOME"));
    
    char *shell_env = getenv("SHELL");
    if (shell_env &&  strstr(shell_env, "zsh")) {
        snprintf(rc_path, sizeof(rc_path), "%s/.zshrc", getenv("HOME"));
    }

    FILE *f = fopen(rc_path, "a+");
    if (!f) return -1;

    // Check if configuration profile already exists
    char line[256];
    int exists = 0;
    while (fgets(line, sizeof(line), f)) {
        if (strstr(line, "GOROOT=")) {
            exists = 1;
            break;
        }
    }

    if (!exists) {
        fprintf(f, "\n# PolyInstall Engine Configuration Linker\n");
        fprintf(f, "export GOROOT=\"%s\"\n", install_path);
        fprintf(f, "export PATH=\"$GOROOT/bin:$PATH\"\n");
    }
    fclose(f);
    return 0;
#endif
}