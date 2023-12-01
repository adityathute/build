# core.py

import sys
from main import arch_linux

def core():
    # Accessing command-line arguments
    os_arg = sys.argv[1] if len(sys.argv) > 1 else "unknown"
    distribution_arg = sys.argv[2] if len(sys.argv) > 2 else "unknown"

    if os_arg == "linux":
        # Function to detect Linux distribution
        if distribution_arg == "arch linux":
            arch_linux()
    else:
        print(f"This script supports Arch Linux only.")

if __name__ == "__main__":
    core()
