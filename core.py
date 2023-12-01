# core.py

import sys

def main():
    # Accessing command-line arguments
    os_arg = sys.argv[1] if len(sys.argv) > 1 else "unknown"
    distribution_arg = sys.argv[2] if len(sys.argv) > 2 else "unknown"

    print(f"OS: {os_arg}, Distribution: {distribution_arg}")

if __name__ == "__main__":
    main()
