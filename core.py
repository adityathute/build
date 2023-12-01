# core.py

import sys

def main():
    # Accessing command-line arguments
    os_arg = sys.argv[1] if len(sys.argv) > 1 else "unknown"

    if os_arg == "linux":
        # Function to detect Linux distribution
        detect_distribution()
    elif os_arg == "macos":
        # Logic for macOS
        print(f"This script supports Arch Linux only. Detected {os_arg} operating system.")
    elif os_arg == "windows":
        # Logic for Windows
        print(f"This script supports Arch Linux only. Detected {os_arg} operating system.")
    else:
        print(f"This script supports Arch Linux only.")

def detect_distribution():
    # Accessing command-line arguments
    distribution_arg = sys.argv[2] if len(sys.argv) > 2 else "unknown"
    pkgmanager_arg = sys.argv[3] if len(sys.argv) > 2 else "unknown"

    if distribution_arg == "arch":
        print(f"Detected Arch Linux....{pkgmanager_arg}")
    elif distribution_arg in ["debian", "ubuntu", "linuxmint"]:
        print(f"This script supports Arch Linux only. Detected {distribution_arg} distribution.")
    elif distribution_arg in ["fedora", "centos", "rhel"]:
        print(f"This script supports Arch Linux only. Detected {distribution_arg} distribution.")
    elif distribution_arg in ["opensuse", "suse"]:
        print(f"This script supports Arch Linux only. Detected {distribution_arg} distribution.")
    else:
        print("This script supports Arch Linux only.")

if __name__ == "__main__":
    main()
