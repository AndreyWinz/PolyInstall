#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(_WIN32) || defined(_WIN64)
    #define PLATFORM_WINDOWS 1
#elif __APPLE__
    #define PLATFORM_MACOS 1
#else
    #define PLATFORM_LINUX 1
#endif

void run_command(const char *cmd) {
    int ret = system(cmd);
    if (ret != 0) {
        fprintf(stderr, "[-] Critical execution failure routing command block: %s\n", cmd);
        exit(1);
    }
}

int main() {
    printf("[+] Launching Pure Native C Installer Engine for Objective-C...\n");

    char cmd_buffer[2048];
    const char *home_dir = getenv("HOME");
    if (!home_dir) {
        home_dir = getenv("USERPROFILE");
    }
    if (!home_dir) {
        fprintf(stderr, "[-] Fatal: Unable to resolve user home profile directory.\n");
        return 1;
    }

#if PLATFORM_WINDOWS
    printf("[+] Windows OS environment verified. Streaming standalone GNUstep components...\n");
    const char *url = "https://github.com/gnustep/tools-windows/releases/download/v1.3/gnustep-core-minimal-x64.zip";
    
    sprintf(cmd_buffer, "powershell -Command \"$t=Join-Path $env:TEMP 'gst.zip'; Invoke-WebRequest -Uri '%s' -OutFile $t -UseBasicParsing; $dest=Join-Path '%s' '.polyinstall\\objc'; if(Test-Path $dest){Remove-Item -Recurse -Force $dest}; New-Item -ItemType Directory -Path $dest | Out-Null; Expand-Archive -Path $t -DestinationPath $dest -Force; $p=[Environment]::GetEnvironmentVariable('PATH','User'); $b=Join-Path $dest 'bin'; if($p -notlike '*'+$b+'*'){[Environment]::SetEnvironmentVariable('PATH', $b+';'+$p, 'User')}\"", url, home_dir);
    run_command(cmd_buffer);

#elif PLATFORM_MACOS
    printf("[+] macOS context verified. Mapping Clang compilation aliases...\n");
    sprintf(cmd_buffer, "mkdir -p \"%s/.polyinstall/objc/bin\"", home_dir);
    run_command(cmd_buffer);

    char script_path[512];
    sprintf(script_path, "%s/.polyinstall/objc/bin/objc-build", home_dir);
    FILE *f = fopen(script_path, "w");
    if (f) {
        fprintf(f, "#!/usr/bin/env zsh\nclang -framework Foundation \"$@\"\n");
        fclose(f);
        sprintf(cmd_buffer, "chmod +x \"%s\"", script_path);
        run_command(cmd_buffer);
    }

    sprintf(cmd_buffer, "grep -q 'POLYINSTALL_OBJC' \"%s/.zshrc\" || echo '\n# POLYINSTALL_OBJC\nexport PATH=\"%s/.polyinstall/objc/bin:$PATH\"' >> \"%s/.zshrc\"", home_dir, home_dir, home_dir);
    run_command(cmd_buffer);

#else // PLATFORM_LINUX
    printf("[+] Linux context verified. Setting up GCC Objective-C bindings...\n");
    sprintf(cmd_buffer, "mkdir -p \"%s/.polyinstall/objc/bin\"", home_dir);
    run_command(cmd_buffer);

    char script_path[512];
    sprintf(script_path, "%s/.polyinstall/objc/bin/objc-build", home_dir);
    FILE *f = fopen(script_path, "w");
    if (f) {
        fprintf(f, "#!/usr/bin/env bash\ngcc -x objective-c \"$@\" -lobjc -lgnustep-base\n");
        fclose(f);
        sprintf(cmd_buffer, "chmod +x \"%s\"", script_path);
        run_command(cmd_buffer);
    }

    sprintf(cmd_buffer, "grep -q 'POLYINSTALL_OBJC' \"%s/.bashrc\" || echo '\n# POLYINSTALL_OBJC\nexport PATH=\"%s/.polyinstall/objc/bin:$PATH\"' >> \"%s/.bashrc\"", home_dir, home_dir, home_dir);
    run_command(cmd_command);
#endif

    printf("[*] SUCCESS: Objective-C automation layer completely registered via native C executable!\n");
    return 0;
}
