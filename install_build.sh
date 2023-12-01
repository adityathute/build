#!/bin/bash

# Function to check the operating system
check_os() { case "$OSTYPE" in linux*) OS="linux";; darwin*) OS="macos";; msys*) OS="windows";; *) OS="unknown";; esac }

# Function to detect Linux distribution
detect_distribution() {
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

# Function to run core.py if it exists
core() { [ -f "core.py" ] && python core.py; }

# Function to set up the build project
build_setup() {
    PROJECTNAME="myProject"
    DESTINATION_DIR="build"  # Specify the destination directory

    if [ -d "$DESTINATION_DIR" ]; then
        cd "$DESTINATION_DIR" || exit 1
        git pull
        core
    else
        git clone https://github.com/adityathute/$DESTINATION_DIR.git "$DESTINATION_DIR"
        cd "$DESTINATION_DIR" || exit 1
        core
    fi

}

# Main script
main() {

    sudo $PKGMANAGER -Sy --noconfirm git github-cli python
    git_config

    # Check if user is already authenticated with GitHub
    if gh auth status &>/dev/null; then
        build_setup
    else
        # If not authenticated, run gh auth login
        echo "You are not authenticated with GitHub. login..."
        if gh auth login; then
            echo "GitHub authentication successful."
            build_setup
        else
            echo "GitHub authentication failed. Exiting."
            exit 1
        fi
    fi
}

# Check operating system & Detect Linux distribution
check_os
detect_distribution

# Check operating system and distribution
if [ "$OS" == "linux" ]; then
    case "$DISTRIBUTION" in
        arch)
            PKGMANAGER="pacman"
            main
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
