#!/bin/bash

# Function to check the operating system
check_os() {
    case "$OSTYPE" in
        linux*)   OS="linux";;
        darwin*)  OS="macos";;
        msys*)    OS="windows";;
        *)        OS="unknown";;
    esac
}

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

git_config() {
    # Check if user.name is already configured
    if [ -z "$(git config --global --get user.name)" ]; then
        read -p "Enter your full name: " USER_NAME

        # Check if USER_NAME is not blank
        while [ -z "$USER_NAME" ]; do
            echo "Name cannot be blank. Please enter your full name: "
            read -p "Enter your full name: " USER_NAME
        done

        git config --global user.name "$USER_NAME"
    fi

    # Check if user.email is already configured
    if [ -z "$(git config --global --get user.email)" ]; then
        read -p "Enter your GitHub email: " USER_EMAIL

        # Check if USER_EMAIL is not blank
        while [ -z "$USER_EMAIL" ]; do
            echo "Email cannot be blank. Please enter your GitHub email: "
            read -p "Enter your GitHub email: " USER_EMAIL
        done

        git config --global user.email "$USER_EMAIL"
    fi
}

core() {
    if [ -f "core.py" ]; then
        echo "Executing core.py..."
        python core.py
    else
        echo "core.py not found. Please check your project structure."
    fi
}

# Function to set up the build project
build_setup() {
    PROJECTNAME="myProject"
    DESTINATION_DIR="build"  # Specify the destination directory

    if [ -d "$DESTINATION_DIR" ]; then
        echo "Project already exists. Updating..."
        cd "$DESTINATION_DIR" || exit 1
        git pull
        core
    else
        echo "Cloning project..."
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
        echo "You are already authenticated with GitHub. Skipping login."
        build_setup
    else
        # If not authenticated, run gh auth login
        echo "You are not authenticated with GitHub. Running gh auth login..."
        if gh auth login; then
            echo "GitHub authentication successful."
            build_setup
        else
            echo "GitHub authentication failed. Exiting."
            exit 1
        fi
    fi

    echo "Installation completed."
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
