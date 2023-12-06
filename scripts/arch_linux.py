# arch_linux.py

import os
import subprocess
import shutil

# Implement alias setting based on distro and OS.
def set_alias(distro, operating_system):

    os.chdir("..")

    # Get the path to the script's directory
    script_directory = os.path.dirname(os.path.abspath(__file__))

    # Specify the path to the alias.txt and .bashrc files relative to the script's directory
    alias_file_path = os.path.join(script_directory, f"os/{operating_system}/{distro}/alias.txt")
    bashrc_file_path = os.path.join(os.path.expanduser("~"), ".bashrc")

    # Check if the file exists before attempting to open it
    if os.path.exists(alias_file_path):
        # Read the content of alias.txt
        with open(alias_file_path, 'r') as alias_file:
            alias_content = alias_file.read()

        # Check if the content is already in .bashrc
        with open(bashrc_file_path, 'r') as bashrc_file:
            bashrc_content = bashrc_file.read()

        # Find the range of content from # Aliases to # end_alises in .bashrc
        start_marker = "# Aliases"
        end_marker = "# end_alises"
        start_index = bashrc_content.find(start_marker)
        end_index = bashrc_content.find(end_marker) + len(end_marker)

        # Check if the range is found
        if start_index != -1 and end_index != -1:
            # Replace the existing range with the new aliases
            updated_bashrc_content = f"{bashrc_content[:start_index]}# Aliases\n{alias_content}\n# end_alises{bashrc_content[end_index:]}"
        else:
            # Add the new aliases to the end of the file
            updated_bashrc_content = f"{bashrc_content}\n# Aliases\n{alias_content}\n# end_alises"

        # Write the updated content to .bashrc
        with open(bashrc_file_path, 'w') as bashrc_file:
            bashrc_file.write(updated_bashrc_content)

        print(f"Aliases added successfully.")

        # Source the updated .bashrc file
        source_command = f"source {bashrc_file_path}"
        # You may want to run this command in a subprocess or shell
        subprocess.run(source_command, shell=True)
    else:
        print(f"File not found: {alias_file_path}")

# Check package is already installed
def is_package_installed(package_name, pkg_manager):
    try:
        subprocess.run([pkg_manager, "-Q", package_name], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return True
    except subprocess.CalledProcessError:
        return False

# Install essential packages
def install_packages(pkg_manager):
    install_pkgs_command = f"sudo {pkg_manager} -S --noconfirm firefox nodejs npm base-devel mariadb"
    subprocess.run(install_pkgs_command, shell=True)

    # Check if 'yay' is installed
    if not is_package_installed("yay", pkg_manager):

        # Check if yay folder exists and remove it
        if os.path.exists("yay"):
            shutil.rmtree("yay")

        # Clone yay repository
        subprocess.run(["git", "clone", "https://aur.archlinux.org/yay.git"], check=True)

        # Change directory to yay
        os.chdir("yay")

        # Build and install yay
        subprocess.run(["makepkg", "-si", "--noconfirm"], check=True)

        # Install additional packages using yay
        subprocess.run(["yay", "-S", "visual-studio-code-bin", "--noconfirm"], check=True)

        # Change back to the original directory
        os.chdir("..")

        # Remove yay folder
        shutil.rmtree("yay")

    print(f"System packages installed successfully.")

def run_command(command):
    try:
        subprocess.run(command, check=True, shell=True)
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")

def config_db_server():
    pass
    # Install MariaDB database
    # run_command("sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql")

    # Enable MariaDB service
    # run_command("sudo systemctl enable mariadb.service")

    # Start MariaDB service
    # run_command("sudo systemctl start mariadb.service")

    # # Connect to MariaDB as root
    # run_command("mysql -u root -e 'FLUSH PRIVILEGES'")
    # run_command("mysql -u root -e \"ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password'\"")

    # # Connect to MariaDB with the new password
    # run_command("mysql -u root -p -e 'CREATE DATABASE mydb'")

    # # Additional commands as needed
    # # ...

    # # Stop MariaDB service
    # run_command("sudo systemctl stop mariadb")

    # # Start MariaDB service again if needed
    # # run_command("sudo systemctl start mariadb")
