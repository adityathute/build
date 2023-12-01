#!/bin/bash

# Function to check the operating system
check_os() { case "$OSTYPE" in linux*) OS="linux";; darwin*) OS="macos";; msys*) OS="windows";; *) OS="unknown";; esac }

# Function to detect Linux distribution
detect_distribution() {
    case "$OS" in
        linux)
            if command -v lsb_release &>/dev/null; then
                DISTRIBUTION=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
            elif [ -e /etc/os-release ]; then
                DISTRIBUTION=$(awk -F= '/^NAME/{gsub(/"/, "", $2); print tolower($2)}' /etc/os-release)
                DISTRIBUTION=${DISTRIBUTION%% *}  # Extract the first word
            elif [ -e /etc/debian_version ]; then
                DISTRIBUTION="debian"
            elif [ -e /etc/redhat-release ]; then
                DISTRIBUTION="rhel"
            else
                DISTRIBUTION="unknown"
            fi
            ;;
        *)
            DISTRIBUTION="unknown"
            ;;
    esac
}

# Function to set up Git configuration
git_config() {
    set_config() {
        local config_key=$1
        local prompt_message=$2
        local empty_message=$3

        if [ -z "$(git config --global --get "$config_key")" ]; then
            read -p "$prompt_message" input_value

            while [ -z "$input_value" ]; do
                echo "$empty_message"
                read -p "$prompt_message" input_value
            done

            git config --global "$config_key" "$input_value"
        fi
    }

    set_config "user.name" "Enter your full name: " "Name cannot be blank. Please enter your full name: "
    set_config "user.email" "Enter your GitHub email: " "Email cannot be blank. Please enter your GitHub email: "
}

# Function to set up the build project
build_linux_setup() {
    DESTINATION_DIR="build_project"       # Specify the destination directory
    BACKUP_DIR="build_project_old"        # Specify the backup directory name

    # Check if build directory exists, move it to build_org
    if [ -d "$DESTINATION_DIR" ]; then
        # Check if build_org directory already exists, if yes, delete it
        if [ -d "$BACKUP_DIR" ]; then
            rm -rf "$BACKUP_DIR" || exit 1
        fi
        mv "$DESTINATION_DIR" "$BACKUP_DIR" || exit 1
    fi

    # Clone the repository into the build directory
    git clone -b Master https://github.com/adityathute/build.git "$DESTINATION_DIR"
    cd "$DESTINATION_DIR" || exit 1

    # Check if core.py exists, and if yes, execute it with OS and DISTRIBUTION parameters
    if [ -f "core.py" ]; then
        python core.py "$OS" "$DISTRIBUTION" "$PKGMANAGER"
    fi
}

# Main script
main_linux() {
    sudo $PKGMANAGER -Sy --noconfirm git github-cli python
    git_config

    # Check if user is already authenticated with GitHub
    if gh auth status &>/dev/null; then
        build_linux_setup
    else
        # If not authenticated, run gh auth login
        echo "You are not authenticated with GitHub. login..."
        if gh auth login; then
            echo "GitHub authentication successful."
            build_linux_setup
        else
            echo "GitHub authentication failed. Exiting."
            exit 1
        fi
    fi
}

# Check operating system & Detect Linux distribution
check_os

# Check operating system and distribution
if [ "$OS" == "linux" ]; then
    detect_distribution
    case "$DISTRIBUTION" in
        arch)
            PKGMANAGER="pacman"
            main_linux
            ;;
        debian | ubuntu | linuxmint | fedora | centos | rhel | opensuse | suse)
            echo "This script supports Arch Linux only. Detected $DISTRIBUTION distribution."
            exit 1
            ;;
        *)
            echo "This script supports Arch Linux only. Detected $DISTRIBUTION distribution."
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
