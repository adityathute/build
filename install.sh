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
        python core.py "$OS" "$DISTRO" "$PKGMANAGER"
    fi
}

# Only for Arch Linux operating system
arch_linux() {
    # Upgrade all installed packages
    echo "Upgrading installed packages..."
    sudo pacman -Syu --noconfirm

    # Install required packages
    sudo pacman -S --noconfirm git github-cli python

    # Configure Git settings
    git_config

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
