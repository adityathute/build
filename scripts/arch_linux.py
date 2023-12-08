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

# Install essential packages
def install_packages(pkg_manager):
    packages = ["firefox", "nodejs", "npm", "base-devel", "mariadb"]
    install_pkgs_command = ["sudo", pkg_manager, "-Sq", "--needed", "--noconfirm"] + packages
    subprocess.run(install_pkgs_command)

    # Check if 'yay' is installed
    if not shutil.which("yay"):

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
        result = subprocess.run(command, shell=True, capture_output=capture_output, text=True, check=True)
        return result.stdout.strip() if capture_output else ""
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e}")
        return "" if capture_output else None
    
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

def create_or_upgrade_root_user(root_password):
    # Check if root user already exists
    root_exists_output = subprocess.run("sudo mariadb -u root -e 'SELECT 1 FROM mysql.user WHERE User = \"root\"'", capture_output=True, text=True, shell=True)
    
    # Check for errors in the output
    if "ERROR" in root_exists_output.stdout.upper():
        print("Error in the command. Check MariaDB logs or investigate further.")
        return
    
    # Check if root user exists
    root_exists = "1" in root_exists_output.stdout.strip()

    if not root_exists:
        # MariaDB root user does not exist, create user and set password
        create_user_command = f"sudo mariadb -u root -p'{root_password}' -e \"CREATE USER IF NOT EXISTS 'root'@'localhost' IDENTIFIED BY 'Anonymous@#633911';\""
        grant_privileges_command = f"sudo mariadb -u root -p'{root_password}' -e \"GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;\""
        flush_privileges_command = f"sudo mariadb -u root -p'{root_password}' -e 'FLUSH PRIVILEGES;'"

        try:
            subprocess.run(create_user_command, shell=True, check=True, text=True)
            subprocess.run(grant_privileges_command, shell=True, check=True, text=True)
            subprocess.run(flush_privileges_command, shell=True, check=True, text=True)
            print("Root privileges have been granted to MariaDB root user.")
        except subprocess.CalledProcessError as e:
            print(f"Error executing command: {e}")
    else:
        print("MariaDB root user already exists.")

def create_database(target_database, root_password):
    # Check if the database exists
    database_exists_output = subprocess.run(f"mariadb -u root -p{root_password} -e 'SHOW DATABASES LIKE \"{target_database}\"'", capture_output=True, text=True, shell=True)

    # Check for errors in the output
    if "ERROR" in database_exists_output.stderr.upper():
        print("Error in the command. Check MariaDB logs or investigate further.")
        return

    # Check if the target database exists
    database_exists = target_database in database_exists_output.stdout.strip().split("\n")

    if not database_exists:
        # The database does not exist, so create it
        create_database_command = f"mariadb -u root -p{root_password} -e 'CREATE DATABASE {target_database}'"
        try:
            subprocess.run(create_database_command, shell=True, check=True, text=True)
            print(f"The database '{target_database}' has been created.")
        except subprocess.CalledProcessError as e:
            print(f"Error executing command: {e}")
    else:
        print(f"The database '{target_database}' already exists.")

def config_db_server(env_path):
    # Specify the database, username, and root password
    target_database = get_env_data(env_path, "DB_NAME", default="")
    user_password = get_env_data(env_path, "DB_PASSWORD", default="")
    root_password = user_password

    if shutil.which("mariadb"):
        # Check if MariaDB service is not active
        if not run_command('sudo systemctl is-active mariadb.service').strip() == "active":
            # Start and enable MariaDB service if not already running
            run_command('sudo systemctl start mariadb.service')
            run_command('sudo systemctl enable mariadb.service')
        else:
            print("MariaDB service is already running.")

        create_or_upgrade_root_user(root_password)
        create_database(target_database, root_password)

def auth_github():
    try:
        # Check GitHub authentication status
        subprocess.run(["gh", "auth", "status"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        # If the above line is successful, it means the user is authenticated
        # Return True to indicate successful authentication
        return True

    except subprocess.CalledProcessError:
        # If the above line raises an error, it means the user is not authenticated
        # Prompt for login and retry
        print("You are not authenticated with GitHub. Logging in...")

        while True:
            try:
                # Attempt GitHub authentication
                subprocess.run(["gh", "auth", "login"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                print("GitHub authentication successful.")
                
                # If authentication is successful, return True
                return True

            except subprocess.CalledProcessError:
                # If authentication fails, prompt user to retry or exit
                print("GitHub authentication failed.")
                choice = input("Press Enter to try again, or 'Q' to exit: ")

                if choice.lower() == 'q':
                    print("Exiting.")
                    return False  # Return False to indicate authentication failure
                else:
                    print("Retrying GitHub authentication...")

def clone_project(env_path):
    prj_name = get_env_data(env_path, "PROJECT_NAME", default="root")
    is_authenticated = auth_github()

    if is_authenticated:
        if prj_name:
            # Check if the project directory exists
            project_directory = os.path.join(os.getcwd(), prj_name)

            if not os.path.exists(project_directory):
                # Clone the GitHub repository if the project directory does not exist
                clone_command = f"git clone -b Master https://github.com/adityathute/{prj_name}.git {prj_name}"
                subprocess.run(clone_command, shell=True, check=True)
                print(f"Project '{prj_name}' cloned successfully.")
            else:
                print(f"Project '{prj_name}' is already cloned.")

def virtual_environment(env_path):
    current_directory = os.getcwd()
    prj_name = get_env_data(env_path, "PROJECT_NAME", default="root")
    project_directory = os.path.join(current_directory, prj_name)
    
    if not os.path.exists("env"):
        # Create a virtual environment
        run_command("python -m venv env")
    
    # Activate the virtual environment manually by setting up environment variables
    activate_script = os.path.join("env", "bin", "activate")
    activate_cmd = f"source {activate_script} && env"
    env_output = run_command(activate_cmd, capture_output=True)

    # Extract environment variables from the activation script output
    env_vars = {line.split("=", 1)[0]: line.split("=", 1)[1] for line in env_output.splitlines()}

    # Set up the environment variables in the current process
    os.environ.update(env_vars)
    
    if not os.path.exists(project_directory):
        clone_project(env_path)
    else:
        os.chdir(project_directory)

        # Print the current working directory
        current_directory = os.getcwd()
        print(f"Current Working Directory: {current_directory}")

        # Install dependencies from requirements.txt
        run_command("pip install -r build/requirements.txt")