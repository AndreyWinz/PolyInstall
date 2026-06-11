#include "installer.hpp"
#include <iostream>

int main() {
    try {
        PhpInstaller installer("8.3.11");
        installer.execute();
    } catch (const std::exception& e) {
        std::cerr << "[-] Critical Fault Event: " << e.what() << std::endl;
        return 1;
    }
    return 0;
}