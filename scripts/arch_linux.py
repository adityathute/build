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

def run_command(command, capture_output=False):
    try:
        if capture_output:
            result = subprocess.run(command, shell=True, capture_output=True, text=True, check=True)
            return result.stdout.strip()
        else:
            subprocess.run(command, shell=True, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e}")
        # You may want to handle the error or raise an exception here

def get_env_data(env_path, input_key, default):

    # Check if the .env file exists
    if os.path.exists(env_path):
        with open(env_path, "r") as file:
            for line in file:
                # Check if the line contains the input key
                if line.startswith(input_key):
                    # Extract the value after the '=' and remove surrounding quotes
                    _, env_input = line.strip().split("=", 1)
                    result = env_input.strip('\'"')
                    return result

    # Return the default value if the input key is not found
    return default

def config_db_server(env_path):
    data_directory = "/var/lib/mysql"

    # Check if MariaDB is already installed
    if not os.path.exists(data_directory):
        # MySQL is not installed, so install it
        install_command = f"sudo mysql_install_db --user=mysql --basedir=/usr --datadir={data_directory}"
        run_command(install_command)

        # Start MariaDB service
        start_command = "sudo systemctl start mariadb"
        run_command(start_command)

    # Set the desired DB_User, password, and database name
    db_user = get_env_data(env_path, "DB_USER", default="root")
    db_password = get_env_data(env_path, "DB_PASSWORD", default="")
    db_name = get_env_data(env_path, "DB_NAME", default="")

    # Check if user and database already exist
    user_exists_command = f"sudo mariadb -u root -p'{db_password}' -e \"SELECT user FROM mysql.user WHERE user='{db_user}'\""
    db_exists_command = f"sudo mariadb -u root -p'{db_password}' -e \"SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='{db_name}'\""

    user_exists = run_command(user_exists_command, capture_output=True).strip()
    db_exists = run_command(db_exists_command, capture_output=True).strip()

    if not user_exists:
        # Command to set root password
        set_password_command = f"sudo mariadb-admin --user='{db_user}' password '{db_password}'"
        run_command(set_password_command)

    # Restart MariaDB service
    restart_command = "sudo systemctl restart mariadb"
    run_command(restart_command)

    if not db_exists:
        # MariaDB commands
        mariadb_commands = [
            f"GRANT ALL PRIVILEGES ON *.* TO '{db_user}'@'localhost' IDENTIFIED BY '{db_password}' WITH GRANT OPTION;",
            "FLUSH PRIVILEGES;",
            f"CREATE DATABASE {db_name};",
        ]

        # Execute MariaDB commands using the 'mariadb' command
        for command in mariadb_commands:
            run_command(f"sudo mariadb -u root -p'{db_password}' -e \"{command}\"")

    # Restart MariaDB service
    run_command(restart_command)

    print(f"Database configuration completed successfully.")
