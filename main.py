# main.py

def set_alias(distro):
    print(f"This is set_alias with {distro}.")

def install_packages(pkg_manager):
    print(f"This is install_packages with {pkg_manager}.")

def arch_linux():
    set_alias("arch_linux")
    install_packages("pacman")
