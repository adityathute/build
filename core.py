# core.py

import sys
from main import arch_linux

def core():
    # Accessing command-line arguments
    os_arg = sys.argv[1] if len(sys.argv) > 1 else "unknown"
    distribution_arg = sys.argv[2] if len(sys.argv) > 2 else "unknown"
    env_file_path = sys.argv[3] if len(sys.argv) > 3 else "unknown"
    build_path = sys.argv[4] if len(sys.argv) >4  else "unknown"

    # Check if the operating system is Linux
    if os_arg == "linux":
        # Check if the distribution is Arch Linux
        if distribution_arg == "arch linux":
            # Call the arch_linux function from the main module
            arch_linux(env_file_path, build_path)
    else:
        print(f"This script supports Arch Linux only.")

if __name__ == "__main__":
    # Execute the core function when the script is run
    core()
