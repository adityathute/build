# main.py

from scripts.arch_linux import set_alias, install_packages, config_db_server

# Configure aliases and install packages for an Arch Linux environment.
def arch_linux():
    set_alias("arch_linux", "linux")
    install_packages("pacman")
    config_db_server()
