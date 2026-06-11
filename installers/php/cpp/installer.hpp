#ifndef INSTALLER_HPP
#define INSTALLER_HPP

#include <string>

class PhpInstaller {
private:
    std::string version;
    std::string installDir;
    std::string tempArchive;

    bool downloadFile(const std::string& url, const std::string& dest);
    bool runCommand(const std::string& cmd);

public:
    PhpInstaller(const std::string& ver);
    void execute();
};

#endif