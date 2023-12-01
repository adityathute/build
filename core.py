# core.py

import sys

def main():
    # Accessing command-line arguments
    os_arg = sys.argv[1] if len(sys.argv) > 1 else "unknown"
    distribution_arg = sys.argv[2] if len(sys.argv) > 2 else "unknown"

    if os_arg == "linux":
        # Function to detect Linux distribution
        detect_distribution()
        print(f"OS: {os_arg}, Distribution: {distribution_arg}")
    elif os_arg == "macos":
        # Logic for macOS
        print(f"OS: {os_arg}")
    elif os_arg == "windows":
        # Logic for Windows
        print(f"OS: {os_arg}")
    else:
        print(f"Unknown")

def detect_distribution():
    # Accessing command-line arguments
    distribution_arg = sys.argv[2] if len(sys.argv) > 2 else "unknown"
    pkgmanager_arg = sys.argv[3] if len(sys.argv) > 2 else "unknown"

    if distribution_arg == "arch":
        print("Detected Arch Linux...." , {pkgmanager_arg})
    elif distribution_arg in ["debian", "ubuntu", "linuxmint"]:
        print(f"Detected {distribution_arg} distribution....")
    elif distribution_arg in ["fedora", "centos", "rhel"]:
        print(f"Detected {distribution_arg} distribution....")
    elif distribution_arg in ["opensuse", "suse"]:
        print(f"Detected {distribution_arg} distribution....")
    else:
        print(f"Unknown distribution....")

if __name__ == "__main__":
    main()
