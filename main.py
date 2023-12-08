# main.py

from scripts.arch_linux import set_alias, install_packages, config_db_server, clone_project, virtual_environment

# Configure aliases and install packages for an Arch Linux environment.
def arch_linux(env_path):
    set_alias("arch_linux", "linux")
    install_packages("pacman")
    config_db_server(env_path)
    # clone_project(env_path)
    # virtual_environment(env_path)
