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

ENV_FILE="build_project/scripts/.env"

get_info() {
  # Check if FULL_NAME is blank in env file
  if [ -z "$FULL_NAME" ]; then
    read -p "Enter your full name: " full_name
    export FULL_NAME="$full_name"

    # Update .env file
    echo "FULL_NAME=$FULL_NAME" >> "$ENV_FILE"
  fi

  # Check if GITHUB_EMAIL is blank in env file
  if [ -z "$GITHUB_EMAIL" ]; then
    read -p "Enter your GitHub email address: " github_email

    # If GitHub email is blank, do not allow continuation
    if [ -z "$github_email" ]; then
      echo "GitHub email cannot be blank. Exiting."
      exit 1
    fi

    export GITHUB_EMAIL="$github_email"

    # Update .env file
    echo "GITHUB_EMAIL=$GITHUB_EMAIL" >> "$ENV_FILE"
  fi
}

# Function to configure or update the database password
config_db_pass() {
    if grep -q "^DB_PASSWORD=" "$ENV_FILE"; then
        # If DB_PASSWORD is already set in the file, read it
        source "$ENV_FILE"
        if [ -z "$DB_PASSWORD" ]; then
            echo "Configuring a new password for DATABASE."
            configure_password
        fi
    else
        # If DB_PASSWORD is not set, configure a new password
        configure_password
    fi

    # Load the environment variables from the .env file
    if [ -f "$ENV_FILE" ]; then
        export $(grep -v '^#' "$ENV_FILE" | xargs)
    fi
}

# Function to configure a new password
configure_password() {
    while true; do
        read -sp "Enter the database password: " db_password
        echo    # Add a newline after the password input
        read -sp "Re-enter the database password for verification: " db_password_verify
        echo    # Add a newline after the verification input

        if [ "$db_password" = "$db_password_verify" ]; then
            # Update the DB_PASSWORD line in the .env file
            sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=$db_password/" "$ENV_FILE"
            echo "Database password configured successfully."
            break   # Break out of the loop if passwords match
        else
            echo "Passwords do not match. Please try again."
        fi
    done
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
    BKUP_DIR="build_project_old"   # Specify the backup directory name

    # Check if build directory exists, move it to build_org
    if [ -d "$DEST_DIR" ]; then
        # Check if build_org directory already exists, if yes, delete it
        if [ -d "$BKUP_DIR" ]; then
            rm -rf "$BKUP_DIR" || exit 1
        fi
        mv "$DEST_DIR" "$BKUP_DIR" || exit 1
    fi

    # Clone the repository into the build directory
    git clone -b Master https://github.com/adityathute/build.git "$DEST_DIR"
    cd "$DEST_DIR" || exit 1

    # Check if core.py exists, and if yes, execute it with OS and DISTRIBUTION parameters
    if [ -f "core.py" ]; then
        python core.py "$OS" "$DISTRO"
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
