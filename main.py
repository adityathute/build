# main.py

from scripts.arch_linux import set_alias, install_packages, config_db_server, clone_project, virtual_environment, install_dependencies, create_configuration, create_migrations_superuser

# Configure aliases and install packages for an Arch Linux environment.
def arch_linux(env_path):
    set_alias("arch_linux", "linux")
    install_packages("pacman")
    config_db_server(env_path)
    clone_project(env_path)
    create_configuration(env_path)
    virtual_environment()
    create_configuration(env_path)
    install_dependencies(env_path)
    create_migrations_superuser("arch_linux", "linux", env_path)