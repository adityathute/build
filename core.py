# core.py

import sys

def main():
    # Accessing command-line arguments
    os_arg = sys.argv[1] if len(sys.argv) > 1 else "unknown"
    distribution_arg = sys.argv[2] if len(sys.argv) > 2 else "unknown"
    pkgmanager_arg = sys.argv[3] if len(sys.argv) > 2 else "unknown"

    if os_arg == "linux":
        # Function to detect Linux distribution
        if distribution_arg == "arch linux":
            print(f"Detected Arch Linux....")
    else:
        print(f"This script supports Arch Linux only.")

if __name__ == "__main__":
    main()
