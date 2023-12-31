#!/bin/bash

# Declare global variables
ENV_FILE="build-1.1.0/scripts/.env"
ERROR_CODE=false
BUILD="build-1.1.0"
CONFIG=false
checkmark_symbol="✓"

# Check if the terminal supports colors
if [ -t 1 ] && command -v tput > /dev/null; then
    color_dark_red=$(tput setaf 1)
    color_light_green=$(tput setaf 2)
    color_blue=$(tput setaf 4)
    color_white=$(tput setaf 7)
    color_grey=$(tput setaf 8)
    color_bold=$(tput bold)
    color_reset=$(tput sgr0)
else
    # Set variables to empty strings if colors are not supported
    color_dark_red=""
    color_light_green=""
    color_blue=""
    color_white=""
    color_grey=""
    color_bold=""
    color_reset=""
fi

# Function to update specific variables in the environment file
update_file() {
    local var_name=$1
    # Check if the environment file exists and source it
    if source_env_file; then
        # Update the environment file based on the specified variable
        if [ "$var_name" = "FULL_USER_NAME" ]; then
            sed -i "s/FULL_USER_NAME=.*/FULL_USER_NAME=$FULL_NAME/" "$ENV_FILE"
        fi
        if [ "$var_name" = "GIT_EMAIL" ]; then
            sed -i "s/GIT_EMAIL=.*/GIT_EMAIL=$GITHUB_EMAIL/" "$ENV_FILE"
        fi
        if [ "$var_name" = "DB_PASSWORD" ]; then
            sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DATABASE_PASSWORD/" "$ENV_FILE"
        fi
    fi
}

# Function to update configuration based on global CONFIG variable
update_config() {
    # Check if CONFIG is set to true
    if [ "$CONFIG" = true ]; then
        # Update specific variables in the environment file
        update_file "FULL_USER_NAME"
        update_file "GIT_EMAIL"
        update_file "DB_PASSWORD"
    fi
}

# Function to set up the clone build
clone_build() {
    # Check if build directory exists
    if [ -d "$BUILD" ]; then
        update_config
        cd "$BUILD" || exit 1

        # Check if core.py exists, and if yes, execute it with OS and DISTRIBUTION parameters
        if [ -f "core.py" ]; then
            python core.py "$OS" "$DISTRO" "$ENV_FILE" "$BUILD"
        fi
    else
        # Clone the repository into the build directory
        curl -SL https://github.com/adityathute/build/archive/refs/tags/v1.1.0.tar.gz | tar -xz
        update_config
        cd "$BUILD" || exit 1

        # Check if core.py exists, and if yes, execute it with OS and DISTRIBUTION parameters
        if [ -f "core.py" ]; then
            python core.py "$OS" "$DISTRO" "$ENV_FILE" "$BUILD"
        fi
    fi
}

# Function to authenticate with GitHub
auth_github() {
    # Check if user is already authenticated with GitHub
    if gh auth status &>/dev/null; then
        # User is authenticated, proceed to clone_build
        config_git
        clone_build
    else
        # User is not authenticated, prompt for login
        echo "${color_dark_red}${color_bold}You are not authenticated with GitHub.${color_reset} ${color_grey}${color_bold}Logging in...${color_reset}"

        while true; do
            # Attempt GitHub authentication
            if gh auth login; then
                echo "${color_light_green}${color_bold}${checkmark_symbol} GitHub authentication successful.${color_reset}"
                config_git
                clone_build
                break
            else
                # GitHub authentication failed
                echo "${color_dark_red}${color_bold}GitHub authentication failed.${color_reset}"

                # Prompt user to retry or exit
                read -rp "${color_white}${color_bold}Press any key to try again, or 'Q' to exit: ${color_reset}" choice

                case "$choice" in
                    [qQ])
                        echo "${color_dark_red}${color_bold}Exiting.${color_reset}"
                        exit 1
                        ;;
                    *)
                        echo "${color_purple}${color_bold}Retrying GitHub authentication...${color_reset}"
                        ;;
                esac
            fi
        done
    fi
}

# Function to set up Git configuration
config_git() {
  # Check if Git user configuration is already set
  if [ -z "$(git config --global user.name)" ] || [ -z "$(git config --global user.email)" ]; then
    if [ -z "$(git config --global user.name)" ]; then
        # Set Git configuration for name
        git config --global user.name "$FULL_NAME_WQ"
    fi
    if [ -z "$(git config --global user.email)" ]; then
        # Set Git configuration for email
        git config --global user.email "$GITHUB_EMAIL"
    fi
    echo "${color_light_green}${color_bold}${checkmark_symbol} GitHub configuration successful.${color_reset}"
  fi
}

# Function to handle system package upgrades and installations
sys_packages() {
    # Upgrade all installed packages
    sudo pacman -Syu --noconfirm

    # Install required packages if not already up to date
    sudo pacman -Sq --needed --noconfirm git github-cli python python-pip
}

# Function to configure a new password
configure_password() {
    while true; do
        read -sp "${color_blue}${color_bold}Generate Database Password: ${color_reset}" db_password
        echo    # Add a newline after the password input

        # Check if the entered password is not blank
        if [ -n "$db_password" ]; then
            read -sp "${color_blue}${color_bold}Confirm Password: ${color_reset}" db_password_verify
            echo    # Add a newline after the verification input

            if [ "$db_password" = "$db_password_verify" ]; then
                break   # Break out of the loop if passwords match
            else
                tput cuu1
                tput el
                tput cuu1
                tput el
                echo "${color_dark_red}${color_bold}Passwords do not match. Please try again.${color_reset}"
            fi
        else
            tput cuu1
            tput el
            echo "${color_dark_red}${color_bold}Blank not allowed. Please enter a valid password.${color_reset}"
        fi
    done
    # Export the value of db_password as an environment variable named DATABASE_PASSWORD
    export DATABASE_PASSWORD="$db_password"
}

# Function to configure or update the database password
config_db_pass() {
    # Check if the environment file exists
    if source_env_file; then
        # Check if DB_PASSWORD is already set in the file
        if [ -z "$DB_PASSWORD" ]; then
            # If DB_PASSWORD is blank, configure a new password
            configure_password
        fi
    else
        # If the environment file doesn't exist, configure a new password
        configure_password
    fi
}

# Function to get user information
get_input_user() {
  local var_name=$1  # Get the variable name as an argument

  while [ -z "${!var_name}" ]; do
    # Prompt the user to enter a value for the specified variable
    read -e -p "${color_blue}${color_bold}Enter your $var_name: ${color_reset}" input_value

    # Remove leading and trailing whitespaces from the input
    input_value=$(echo "$input_value" | xargs)

    # Check if the input value is empty
    if [ -z "$input_value" ]; then
        tput cuu1
        tput el
        echo "${color_dark_red}${color_bold}Blank not allowed. Please enter a valid value.${color_reset}"
    else
        # Check if the variable name is "FULL_NAME"
        if [ "$var_name" = "FULL_NAME" ]; then
            # Transform the input to title case (capitalize the first letter of each word)
            formatted_value=$(echo "$input_value" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1' | sed 's/^"\(.*\)"$/\1/')
            # Enclose the formatted value in double quotes
            formatted_value="\"$formatted_value\""
            # Update the input value with the formatted value
            input_value="$formatted_value"
        fi

        # Check if the variable name is "GITHUB_EMAIL"
        if [ "$var_name" = "GITHUB_EMAIL" ]; then
            # Convert the input value to lowercase
            input_value=$(echo "$input_value" | tr '[:upper:]' '[:lower:]')
        fi

        # Assign the input value to the global variable
        eval "$var_name=\$input_value"
    fi
  done
}

# Function to check and set the value of a specified variable
check_input_file() {
    local VARIABLE_TO_CHECK=$1  # Get the variable name as an argument

    # Extract the value of the specified variable from the environment file
    VARIABLE_VALUE=$(grep "^$VARIABLE_TO_CHECK=" "$ENV_FILE" | cut -d '=' -f2- | tr -d '[:space:]')

    # Check if the variable value is empty
    if [ -z "$VARIABLE_VALUE" ]; then
        # Variable is not set, set it based on conditions

        # Check if the variable to set is "FULL_USER_NAME"
        if [ "$VARIABLE_TO_CHECK" = "FULL_USER_NAME" ]; then
            # If yes, prompt user for "FULL_NAME"
            get_input_user "FULL_NAME"
        # Check if the variable to set is "GIT_EMAIL"
        elif [ "$VARIABLE_TO_CHECK" = "GIT_EMAIL" ]; then
            # If yes, prompt user for "GITHUB_EMAIL"
            get_input_user "GITHUB_EMAIL"
        # Check if the variable to set is "DB_PASSWORD"
        elif [ "$VARIABLE_TO_CHECK" = "DB_PASSWORD" ]; then
            # If yes, configure the database password
            config_db_pass
        fi

        # Update specific variables in the environment file
        update_file "$VARIABLE_TO_CHECK"

    fi
}

# Function to hide a password by replacing its second half with asterisks
hide_password() {
    # Assign the value of the DATABASE_PASSWORD environment variable to the 'password' variable
    password="$DATABASE_PASSWORD"

    # Check the length of the password
    password_length=${#password}

    # Calculate the number of characters to hide (half of the password)
    half_length=$(( password_length / 2 ))

    # Extract the first half of the password
    first_half="${password:0:$half_length}"

    # Replace the second half with asterisks
    hidden_password="$first_half$(printf '*%.0s' $(seq $((password_length - half_length))))"
    # Assign the hidden password to the DB_HIDE_PASSWORD environment variable
    DB_HIDE_PASSWORD=$hidden_password
}

# Function to check and set the value of a configuration variable
check_configuration() {
    local CHECK_VAR=$1  # Get the variable name as an argument
    local CHECK_VAR_NAME=$2  # Get the variable name as an argument

    # Check if the variable is empty
    if [ -z "${!CHECK_VAR}" ]; then
        # If empty, get the name from the environment file (assuming the variable is defined in the file)
        if source_env_file; then
            # Set the variable based on its name and handle special cases
            if [ "$CHECK_VAR" = "FULL_NAME" ]; then
                eval "$CHECK_VAR=\${$CHECK_VAR_NAME}"
                FULL_NAME_WQ=$FULL_NAME
            elif [ "$CHECK_VAR" = "DATABASE_PASSWORD" ]; then
                eval "$CHECK_VAR=\${$CHECK_VAR_NAME}"
                hide_password
            elif [ "$CHECK_VAR" = "DB_USER" ]; then
                eval "$CHECK_VAR=\${$CHECK_VAR_NAME:-root}"
            else
                eval "$CHECK_VAR=\${$CHECK_VAR_NAME}"
            fi
        else
            # If the environment file is not sourced, set default values based on variable name
            if [ "$CHECK_VAR" = "PROJECT_NAME" ]; then
                PROJECT_NAME="myProject"
            fi

            if [ "$CHECK_VAR" = "DB_NAME" ]; then
                DB_NAME="myDatabase"
            fi

            if [ "$CHECK_VAR" = "DB_USER" ]; then
                DB_USER="root"
            fi
        fi
    else
        # If the variable is not empty, handle special cases
        if [ "$CHECK_VAR" = "FULL_NAME" ]; then
            FULL_NAME_WQ=$(echo "$FULL_NAME" | tr -d '"')
        fi
        if [ "$CHECK_VAR" = "DATABASE_PASSWORD" ]; then
            hide_password
        fi
    fi
}

# Function to source the environment file
source_env_file() {
  if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
    return 0  # Return true (0) to indicate success
  else
    return 1  # Return false (1) to indicate failure
  fi
}

# Function to verify and display configuration information
verification() {
    # Prompt the user to press any key before continuing
    formatted_OS=$(echo "$OS" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
    
    # Format and display the distribution information if available
    if [ ! -z "${DISTRO}" ]; then
        formatted_DISTRO=$(echo "$DISTRO" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1' | sed 's/^/(/;s/$/)/')
    fi

    # Check and set various configuration variables
    check_configuration "FULL_NAME" "FULL_USER_NAME"
    check_configuration "GITHUB_EMAIL" "GIT_EMAIL"
    check_configuration "PROJECT_NAME" "PROJECT_NAME"
    check_configuration "DB_NAME" "DB_NAME"
    check_configuration "DB_USER" "DB_USER"
    check_configuration "DATABASE_PASSWORD" "DB_PASSWORD"

    # Print a success message
    echo -n "${color_light_green}${color_bold}${checkmark_symbol} Configuration has been successfully established.${color_reset}"
    echo  # This adds a new line

    # Print the formatted information in a double-line colorful box
    printf "${color_grey}%-18s : %-44s\n" "System Info" "${color_white}$formatted_OS $formatted_DISTRO${color_reset}"
    printf "${color_grey}%-18s : %-44s\n" "Full Name" "${color_white}$FULL_NAME_WQ${color_reset}"
    printf "${color_grey}%-18s : %-44s\n" "Github Email" "${color_white}$GITHUB_EMAIL${color_reset}"
    printf "${color_grey}%-18s : %-44s\n" "Project Name" "${color_white}$PROJECT_NAME${color_reset}"
    printf "${color_grey}%-18s : %-44s\n" "DataBase Name" "${color_white}$DB_NAME${color_reset}"
    printf "${color_grey}%-18s : %-44s\n" "DataBase User" "${color_white}$DB_USER${color_reset}"
    printf "${color_grey}%-18s : %-44s\n" "DataBase Password" "${color_white}$DB_HIDE_PASSWORD${color_reset}"
    # Add more information as needed

    # Prompt the user to press any key before continuing
    echo -n "${color_white}${color_bold}Press any key to continue${color_reset}..." && read -n 1 -s && echo -e "\r\033[K${color_white}${color_bold}Continuing with the script${color_reset}..."
}

# Function to initialize configuration
initialization() {
    # check BUILD folder is found
    if [ -d "$BUILD" ]; then
        # If BUILD folder is found, try sourcing environment file
        if source_env_file; then
            # Environment file found, check input files
            check_input_file "FULL_USER_NAME"
            check_input_file "GIT_EMAIL"
            check_input_file "DB_PASSWORD"
            CONFIG=false
        else
            # Environment file not found, prompt user for input
            get_input_user "FULL_NAME"
            get_input_user "GITHUB_EMAIL"
            config_db_pass
            CONFIG=true
        fi
    else
        # BUILD folder not found, prompt user for input
        get_input_user "FULL_NAME"
        get_input_user "GITHUB_EMAIL"
        config_db_pass
        CONFIG=true
    fi
}

# Function to handle Arch Linux specific configuration
arch_linux() {
    # Initialization - Checks and sets initial configuration
    initialization

    # Verification - Checks and verify set configuration
    verification

    # Upgrade and install system packages
    sys_packages

    # Authenticate with GitHub
    auth_github
}

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

# Function to check the operating system based on OSTYPE
check_os() {
    case "$OSTYPE" in
        linux*) OS="linux";;
        darwin*) OS="macos";;
        msys*) OS="windows";;
        *) OS="unknown";;
    esac
}

# Call the check_os function to determine the operating system
check_os

# Check the operating system and take appropriate actions
if [ "$OS" == "linux" ]; then
    # If the operating system is Linux, detect the distribution
    detect_distribution

    # Check the detected distribution and perform actions accordingly
    case "$DISTRO" in
        "arch linux")
            arch_linux
            ;;
        "debian" | "ubuntu" | "linuxmint" | "fedora" | "centos" | "rhel" | "opensuse" | "suse")
            echo "${color_dark_red}${color_bold}This script supports Arch Linux only. Detected $DISTRO distribution.${color_reset}"
            exit 1
            ;;
        *)
            echo "${color_dark_red}${color_bold}This script supports Arch Linux only. Detected $DISTRO distribution.${color_reset}"
            exit 1
            ;;
    esac
elif [ "$OS" == "macos" ]; then
    # If the operating system is macOS, print an error message and exit
    echo "${color_dark_red}${color_bold}This script supports Arch Linux only. Detected $OS operating system.${color_reset}"
    exit 1
elif [ "$OS" == "windows" ]; then
    # If the operating system is Windows, print an error message and exit
    echo "${color_dark_red}${color_bold}This script supports Arch Linux only. Detected $OS operating system.${color_reset}"
    exit 1
else
    # If the operating system is unknown, print an error message and exit
    echo "${color_dark_red}${color_bold}Unsupported operating system. Exiting.${color_reset}"
    exit 1
fi
