# core.py

import sys

def main():
    # Accessing command-line arguments
    os_arg = sys.argv[1] if len(sys.argv) > 1 else "unknown"
    distribution_arg = sys.argv[2] if len(sys.argv) > 2 else "unknown"

    if os_arg == "linux":
        # Function to detect Linux distribution
        detect_distribution()
    elif os_arg == "macos":
        # Logic for macOS
        print(f"OS: {os_arg}")
    elif os_arg == "windows":
        # Logic for Windows
        print(f"OS: {os_arg}")
    else:
        print(f"Unknown")

def detect_distribution():
    print(f"Unknown")

if __name__ == "__main__":
    main()
