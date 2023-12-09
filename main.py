# main.py

# Import functions from the scripts.arch_linux module
from scripts.arch_linux import set_alias, install_packages, config_db_server, clone_project, virtual_environment, install_dependencies, create_configuration, create_migrations, clean_build, summary

# Build Project for an Arch Linux environment
def arch_linux(env_path, build_path):
    # Step 1: Set alias and install system packages
    set_alias("arch_linux", "linux")
    install_packages("pacman")

    # Step 2: Configure database server and clone the project
    config_db_server(env_path)
    clone_project(env_path)

    # Step 3: Set up virtual environment, create configuration, and install dependencies
    virtual_environment()
    create_configuration(env_path)
    install_dependencies(env_path)

    # Step 4: Generate migrations and clean build
    create_migrations("arch_linux", "linux", env_path)
    clean_build(build_path)

    # Final step: Display a summary of the actions performed
    summary()
