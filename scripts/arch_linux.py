# arch_linux.py

import os
import subprocess
import shutil
import filecmp
import secrets
import string

# Implement alias setting based on distro and OS.
def set_alias(distro, operating_system):

    os.chdir("..")

    # Get the path to the script's directory
    script_directory = os.path.dirname(os.path.abspath(__file__))

    # Specify the path to the alias.txt and .bashrc files relative to the script's directory
    alias_file_path = os.path.join(script_directory, f"os/{operating_system}/{distro}/alias.txt")
    bashrc_file_path = os.path.join(os.path.expanduser("~"), ".bashrc")

    # Check if the file exists before attempting to open it
    if os.path.exists(alias_file_path) and os.path.exists(bashrc_file_path):
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

        print(f"success: aliases updated successfully.")

        # Source the updated .bashrc file
        source_command = f"source {bashrc_file_path}"
        # You may want to run this command in a subprocess or shell
        subprocess.run(source_command, shell=True)
    else:
        if not os.path.exists(alias_file_path):
            print(f"Error: File not found - {alias_file_path}")
        if not os.path.exists(bashrc_file_path):
            print(f"Error: File not found - {bashrc_file_path}")

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

def start_enable_mariadb_service():
    # Attempt to initialize the system tables
    subprocess.run(['sudo', 'mariadb-install-db', '--user=mysql', '--basedir=/usr', '--datadir=/var/lib/mysql'])

    # Check if MariaDB service is not active
    status_output = subprocess.run(['sudo', 'systemctl', 'is-active', 'mariadb.service'], stdout=subprocess.PIPE, text=True)
    
    if not status_output.stdout.strip() == "active":
        # Start and enable MariaDB service if not already running
        subprocess.run(['sudo', 'systemctl', 'start', 'mariadb.service'])
        subprocess.run(['sudo', 'systemctl', 'enable', 'mariadb.service'])
        
        print("success: mariaDB service is started and enabled.")
    else:
        print("warning: mariaDB service is already running.")

def create_database(target_database):
    # Check if the database exists
    try:
        subprocess.run(['sudo', 'mariadb', '-e', f"USE {target_database};"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        print(f"warning: {target_database} detected -- skipping ")
    except subprocess.CalledProcessError:
        # If the database doesn't exist, create it
        try:
            subprocess.run(['sudo', 'mariadb', '-e', f"CREATE DATABASE {target_database};"])
            print(f"success: {target_database} created.")
        except subprocess.CalledProcessError as e:
            print(f"Error creating database: {e}")

def set_root_password(new_password):
    try:
        # Execute the mariadb command to set the root password
        command = f"sudo mariadb -e \"SET PASSWORD FOR 'root'@'localhost' = PASSWORD('{new_password}')\""
        subprocess.run(command, shell=True, check=True)

        print("success: root password set successfully!")

    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")

def config_db_server(env_path):
    # Specify the database, username, and root password
    target_database = get_env_data(env_path, "DB_NAME", "myDatabase")
    root_password = get_env_data(env_path, "DB_PASSWORD", "root")

    if shutil.which("mariadb"):
        # Check if MariaDB service is not active
        start_enable_mariadb_service()
        create_database(target_database)
        set_root_password(root_password)

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
    prj_name = get_env_data(env_path, "PROJECT_NAME", "myProject")
    is_authenticated = auth_github()

    if is_authenticated:
        if prj_name:
            # Check if the project directory exists
            project_directory = os.path.join(os.getcwd(), prj_name)

            if not os.path.exists(project_directory):
                # Clone the GitHub repository if the project directory does not exist
                clone_command = f"git clone -b Master https://github.com/adityathute/{prj_name}.git {prj_name}"
                subprocess.run(clone_command, shell=True, check=True)
                print(f"success: {prj_name} cloned successfully!")

            else:
                print(f"warning: {prj_name} is already cloned -- skipping")

def virtual_environment():
    if not os.path.exists("env"):
        # Create a virtual environment
        print(f"creating virtual environment...")
        run_command("python -m venv env")
    
    # Activate the virtual environment manually by setting up environment variables
    activate_script = os.path.join("env", "bin", "activate")
    activate_cmd = f"source {activate_script} && env"
    env_output = run_command(activate_cmd, capture_output=True)

    # Extract environment variables from the activation script output
    env_vars = {line.split("=", 1)[0]: line.split("=", 1)[1] for line in env_output.splitlines()}

    # Set up the environment variables in the current process
    os.environ.update(env_vars)

def remove_package_lock():
    pkg_lock_json="./package-lock.json"

    # Check if the package-lock.json file exists
    if os.path.exists(pkg_lock_json):
        # If it exists, delete the file
        os.remove(pkg_lock_json)

def config_npm(prj_name):
    pkg_json="./package.json"
    pkg_json_location = f"{prj_name}/build/package.json"

    if not os.path.exists(pkg_json):
        # If not, copy it from the source location
        remove_package_lock()
        shutil.copy(pkg_json_location, pkg_json)
    else:
        # Read the content of both files
        with open(pkg_json, 'r') as dest_file, open(pkg_json_location, 'r') as src_file:
            dest_content = dest_file.read()
            src_content = src_file.read()

        # Compare content
        if dest_content != src_content:
            remove_package_lock()
            # If content is different, update the package.json file
            shutil.copy(pkg_json_location, pkg_json)

def install_dependencies(env_path):
    prj_name = get_env_data(env_path, "PROJECT_NAME", "myProject")

    # Install dependencies from requirements.txt
    run_command(f"pip install -r {prj_name}/build/requirements.txt")

    # Install npm
    config_npm(prj_name)
    run_command("npm install")

def generate_secret_key(length=64):
    # Define the characters to be used in the secret key
    characters = string.ascii_letters + string.digits + string.punctuation

    # Generate a random string using the defined characters
    return ''.join(secrets.choice(characters) for _ in range(length))

def validate_files_exist(*file_paths):
    for file_path in file_paths:
        if not os.path.exists(file_path):
            raise FileNotFoundError(file_path)

def is_env_file_up_to_date(new_env_path, env_path, config_path):
    return filecmp.cmp(new_env_path, env_path) and filecmp.cmp(new_env_path, config_path)

def update_env_file(new_env_path, env_path, config_path):
    with open(new_env_path, 'w') as new_env_file:
        with open(env_path, 'r') as env_file:
            new_env_file.write(env_file.read())

        new_env_file.write('\n')

        with open(config_path, 'r') as config_file:
            new_env_file.write(config_file.read())

        new_env_file.write(f'SECRET_KEY="{generate_secret_key()}"\n')

    # Add file permission (chmod)
    os.chmod(new_env_path, 0o600)  # Set permission to read and write only for the owner

def create_env_file(new_env_path, env_path, config_path):
    with open(new_env_path, 'w') as new_env_file:
        with open(env_path, 'r') as env_file:
            new_env_file.write(env_file.read())

        new_env_file.write('\n')

        with open(config_path, 'r') as config_file:
            new_env_file.write(config_file.read())

        new_env_file.write(f'SECRET_KEY="{generate_secret_key()}"\n')

    # Add file permission (chmod)
    os.chmod(new_env_path, 0o600)  # Set permission to read and write only for the owner

def create_configuration(env_path):
    prj_name = get_env_data(env_path, "PROJECT_NAME", "myProject")
    config_path = os.path.join(prj_name, "build", "config.txt")
    new_env_path = ".env"

    if os.path.exists(env_path) and os.path.exists(config_path):
        current_directory = os.getcwd()
        new_env_path = os.path.join(current_directory, new_env_path)

        if os.path.exists(new_env_path):
            if not is_env_file_up_to_date(new_env_path, env_path, config_path):
                update_env_file(new_env_path, env_path, config_path)
                print(f"success: configuration updated at {new_env_path} file!")
            else:
                print(".env file is already up to date.")
        else:
            create_env_file(new_env_path, env_path, config_path)
            print(f"success: configuration created at {new_env_path} file!")
    else:
        if os.path.exists(env_path):
            print(f"Error: File not found - {env_path}")
        if os.path.exists(config_path):
            print(f"Error: File not found - {config_path}")

def extract_adm_function(alias_file_path):
    adm_function_found = False
    adm_function_content = []

    with open(alias_file_path, "r") as alias_file:
        for line in alias_file:
            if "function adm {" in line:
                adm_function_found = True
            elif adm_function_found and line.strip() == "}":
                break
            elif adm_function_found:
                adm_function_content.append(line.strip())

    return adm_function_content

def create_migrations_superuser(distro, operating_system, env_path):
    # prj_name = get_env_data(env_path, "PROJECT_NAME", "myProject")
        
    # # Get the path to the script's directory
    # script_directory = os.path.dirname(os.path.abspath(__file__))

    # # Specify the path to the alias.txt and .bashrc files relative to the script's directory
    # alias_file_path = os.path.join(script_directory, f"os/{operating_system}/{distro}/alias.txt")

    # # Extract 'adm' function content
    # adm_function_content = extract_adm_function(alias_file_path)

    # # Get the path to the project directory
    # project_directory = os.path.join(os.getcwd(), prj_name)

    # # Change the current working directory to the project directory
    # os.chdir(project_directory)

    # # Run each line from 'adm' function content as a command
    # for command in adm_function_content:
    #     run_command(command)
    pass