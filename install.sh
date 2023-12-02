#!/bin/bash

# Function to check the operating system
check_os() {
    case "$OSTYPE" in
        linux*) OS="linux";;
        darwin*) OS="macos";;
        msys*) OS="windows";;
        *) OS="unknown";;
    esac
}

# Check operating system
check_os

# Function to detect distribution
detect_distribution() {
    case "$OS" in
        linux)
            if command -v lsb_release &>/dev/null; then
                # Check using lsb_release command
                DISTRO=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
            elif [ -e /etc/os-release ]; then
                # Check using /etc/os-release file
                DISTRO=$(awk -F= '/^NAME/{gsub(/"/, "", $2); print tolower($2)}' /etc/os-release)
            elif [ -e /etc/debian_version ]; then
                # Debian-based distributions
                DISTRO="debian"
            elif [ -e /etc/redhat-release ]; then
                # Red Hat-based distributions
                DISTRO="rhel"
            elif [ -e /etc/gentoo-release ]; then
                # Gentoo Linux
                DISTRO="gentoo"
            elif [ -e /etc/arch-release ]; then
                # Arch Linux
                DISTRO="arch linux"
            elif [ -e /etc/fedora-release ]; then
                # Fedora
                DISTRO="fedora"
            elif [ -e /etc/suse-release ] || [ -e /etc/SuSE-release ]; then
                # SuSE and openSUSE
                DISTRO="suse"
            else
                # Fallback to "unknown" if no known distribution is detected
                DISTRO="unknown"
            fi
            ;;
        *)
            DISTRO="unknown"
            ;;
    esac
}

# Declare global variables
ENV_FILE="build_project/scripts/.env"

# Function to check if the environment file exists and source it
source_env_file() {
  if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
    return 0  # Return true (0) to indicate success
  else
    return 1  # Return false (1) to indicate failure
  fi
}

# Function to get user information
get_info_user() {
  local var_name=$1  # Get the variable name as an argument

  while [ -z "${!var_name}" ]; do
    # Check if the variable exists globally
    if [ -n "${!var_name}" ]; then
      echo "$var_name is already set to ${!var_name}."
      return
    fi

    read -p "Enter your $var_name: " input_value
    input_value=$(echo "$input_value" | xargs)

    if [ -z "$input_value" ]; then
      echo "Blank not allowed. Please enter a valid value."
    else
      # Capitalize the first letter of each word only if var_name is "FULL_NAME"
      if [ "$var_name" = "FULL_NAME" ]; then
        input_value=$(echo "$input_value" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1')
      fi
      
      # Convert email to lowercase if var_name is "GITHUB_EMAIL"
      if [ "$var_name" = "GITHUB_EMAIL" ]; then
        input_value=$(echo "$input_value" | tr '[:upper:]' '[:lower:]')
      fi

      # Assign the input value to the global variable
      eval "$var_name=\$input_value"
    fi
  done
}

get_info() {
  # Check if the environment file exists and source it
  if source_env_file; then
    echo "ENV file is found."
  else
    get_info_user "FULL_NAME"
    get_info_user "GITHUB_EMAIL"
  fi
}

# Function to configure or update the database password
config_db_pass() {
    # Check if the environment file exists
    if source_env_file; then
        # Check if DB_PASSWORD is already set in the file
        if [ -z "$DB_PASSWORD" ]; then
            # If DB_PASSWORD is blank, configure a new password
            echo "Configuring a new password for DATABASE."
            configure_password
        fi
    else
        # If the environment file doesn't exist, configure a new password
        echo "Configuring a new password for DATABASE."
        configure_password
    fi
}

# Function to configure a new password
configure_password() {
    while true; do
        read -sp "Enter the database password: " db_password
        echo    # Add a newline after the password input

        # Check if the entered password is not blank
        if [ -n "$db_password" ]; then
            read -sp "Re-enter the database password: " db_password_verify
            echo    # Add a newline after the verification input

            if [ "$db_password" = "$db_password_verify" ]; then
                echo "Database password configured successfully."
                break   # Break out of the loop if passwords match
            else
                echo "Passwords do not match. Please try again."
            fi
        else
            echo "Password cannot be blank. Please enter a valid password."
        fi
    done
    export DATABASE_PASSWORD="$db_password"
}

# Function to update configuration
update_config() {
    # Check if the .env file exists
    if source_env_file; then
        # Check if FULL_NAME is not blank, update
        if [ ! -z "$FULL_NAME" ]; then
            sed -i "s/USER_NAME=.*/USER_NAME=$FULL_NAME/" "$ENV_FILE"
        fi

        # Check if GITHUB_EMAIL is not blank, update
        if [ ! -z "$GITHUB_EMAIL" ]; then
            sed -i "s/GIT_EMAIL=.*/GIT_EMAIL=$GITHUB_EMAIL/" "$ENV_FILE"
        fi

        # Check if DB_PASSWORD is not blank, update
        if [ ! -z "$DATABASE_PASSWORD" ]; then
            sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DATABASE_PASSWORD/" "$ENV_FILE"
        fi
    fi
}

# Function to set up Git configuration
config_git() {
  # Check if Git user configuration is already set
  if [ -z "$(git config --global user.name)" ] || [ -z "$(git config --global user.email)" ]; then
    # Set Git configuration for name and email
    git config --global user.name "$FULL_NAME"
    git config --global user.email "$GITHUB_EMAIL"

    echo "Git configuration set successfully."
  else
    echo "Git user configuration is already set. Skipping configuration."
  fi
}

# Function to set up the clone build
clone_build() {
    DEST_DIR="build_project"       # Specify the destination directory

    # Check if build directory exists
    if [ -d "$DEST_DIR" ]; then
        update_config
        cd "$DEST_DIR" || exit 1

        # Check if core.py exists, and if yes, execute it with OS and DISTRIBUTION parameters
        if [ -f "core.py" ]; then
            python core.py "$OS" "$DISTRO"
        fi
    else
        # Clone the repository into the build directory
        git clone -b Master https://github.com/adityathute/build.git "$DEST_DIR"
        update_config
        cd "$DEST_DIR" || exit 1

        # Check if core.py exists, and if yes, execute it with OS and DISTRIBUTION parameters
        if [ -f "core.py" ]; then
            python core.py "$OS" "$DISTRO"
        fi
    fi
}

# Only for Arch Linux operating system
arch_linux() {
    get_info
    config_db_pass

    # Upgrade all installed packages
    sudo pacman -Syu --noconfirm

    # Install required packages
    sudo pacman -S --noconfirm git github-cli python

    # Configure Git settings
    config_git

    # Check if user is already authenticated with GitHub
    if gh auth status &>/dev/null; then
        clone_build
    else
        # If not authenticated, run gh auth login
        echo "You are not authenticated with GitHub. Logging in..."

        while true; do
            if gh auth login; then
                echo "GitHub authentication successful."
                clone_build
                break
            else
                echo "GitHub authentication failed."

                read -rp "Press any key to try again, or 'Q' to exit: " choice

                case "$choice" in
                    [qQ])
                        echo "Exiting."
                        exit 1
                        ;;
                    *)
                        echo "Retrying GitHub authentication..."
                        ;;
                esac
            fi
        done
    fi
}

# Check operating system and distribution and also package manager
if [ "$OS" == "linux" ]; then
    detect_distribution
    case "$DISTRO" in
        "arch linux")
            arch_linux
            ;;
        "debian" | "ubuntu" | "linuxmint" | "fedora" | "centos" | "rhel" | "opensuse" | "suse")
            echo "This script supports Arch Linux only. Detected $DISTRO distribution."
            exit 1
            ;;
        *)
            echo "This script supports Arch Linux only. Detected $DISTRO distribution."
            exit 1
            ;;
    esac
elif [ "$OS" == "macos" ]; then
    echo "This script supports Arch Linux only. Detected $OS operating system."
    exit 1
elif [ "$OS" == "windows" ]; then
    echo "This script supports Arch Linux only. Detected $OS operating system."
    exit 1
else
    echo "Unsupported operating system. Exiting."
    exit 1
fi
