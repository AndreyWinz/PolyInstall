import java.io.*;
import java.util.Map;

public class RInstaller {
    private static final String R_VERSION = "4.4.2";

    public static void main(String[] args) {
        System.out.println("[+] Initializing Cross-Language Java Installer Layer for R...");

        String os = System.getProperty("os.name").toLowerCase();
        String homeDir = System.getProperty("user.home");
        String installDir = homeDir + File.separator + ".polyinstall" + File.separator + "r";
        String tempDir = System.getProperty("java.io.tmpdir") + File.separator + "PolyInstallR";

        new File(tempDir).mkdirs();

        try {
            if (os.contains("win")) {
                String exeFile = "R-" + R_VERSION + "-win.exe";
                String url = "https://cran.r-project.org/bin/windows/base/old/" + R_VERSION + "/" + exeFile;
                String destPath = tempDir + File.separator + exeFile;

                System.out.println("[+] Pulling official R executable target for Windows from: " + url);
                runProcess("powershell", "-Command", "Invoke-WebRequest -Uri '" + url + "' -OutFile '" + destPath + "' -UseBasicParsing");

                System.out.println("[+] Extracting installer payloads silently into user folder boundaries...");
                runProcess(destPath, "/VERYSILENT", "/CURRENTUSER", "/DIR=" + installDir);

                System.out.println("[+] Updating continuous user variable path environments...");
                runProcess("powershell", "-Command", "$p=[Environment]::GetEnvironmentVariable('PATH','User'); $r='" + installDir + "\\bin\\x64'; if($p -notlike '*'+$r+'*'){[Environment]::SetEnvironmentVariable('PATH',\"$r;$p\",'User')}");
            } else {
                String tarball = "R-" + R_VERSION + ".tar.gz";
                String url = "https://cran.r-project.org/src/base/R-4/" + tarball;
                String destPath = tempDir + File.separator + tarball;

                System.out.println("[+] Fetching R source mirror package code distribution: " + url);
                runProcess("curl", "-sSL", "-o", destPath, url);

                System.out.println("[+] Breaking down structural tar compressed contents...");
                String srcDir = tempDir + File.separator + "source";
                new File(srcDir).mkdirs();
                runProcess("tar", "-xzf", destPath, "-C", srcDir, "--strip-components=1");

                System.out.println("[+] Starting native make compilation structures (sandboxed user-space prefix)...");
                String buildShell = "cd " + srcDir + " && ./configure --prefix=\"" + installDir + "\" --with-x=no --with-recommended-packages=no && make -j2 && make install";
                runProcess("sh", "-c", buildShell);

                System.out.println("[+] Committing shell path mapping configuration fields...");
                String shell = System.getenv("SHELL");
                String rcName = (shell != null && shell.contains("zsh")) ? ".zshrc" : ".bashrc";
                String rcPath = homeDir + File.separator + rcName;

                try (FileWriter fw = new FileWriter(rcPath, true);
                     BufferedWriter bw = new BufferedWriter(fw);
                     PrintWriter out = new PrintWriter(bw)) {
                    out.println("\n# PolyInstall R Setup\nexport PATH=\"" + installDir + "/bin:$PATH\"");
                }
            }
            System.out.println("[*] SUCCESS: R Language workspace lifecycle completely mapped!");
        } catch (Exception e) {
            System.err.println("[-] Critical error encountered within runtime execution matrix: " + e.getMessage());
            System.exit(1);
        }
    }

    private static void runProcess(String... command) throws Exception {
        ProcessBuilder pb = new ProcessBuilder(command);
        pb.inheritIO();
        Process process = pb.start();
        int exitCode = process.waitFor();
        if (exitCode != 0) {
            throw new RuntimeException("Subprocess execution returned a non-zero exit error state code: " + exitCode);
        }
    }
}
