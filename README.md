Markdown
# AppCleaner.sh

A lightweight, robust, and safe shell script to completely uninstall macOS applications and sweep away their leftover configuration files, caches, and logs. It is fully compatible with the native macOS Bash 3.2 shell and handles strict Bash runtime options (`set -euo pipefail`).

## Features

- **Robust App Detection:** Leverages macOS Spotlight (`mdfind`) for instant tracking, falling back to deep directory scans if Spotlight indexing is disabled.
- **Smart Matching:** Searches for leftovers using the original app name, a space-stripped variant (e.g., matching both `Mullvad Browser` and `MullvadBrowser`), and the app's unique `CFBundleIdentifier` bundle ID.
- **Dry-Run Guard:** Preview exactly what files will be targeted before touching anything on disk.
- **Safe Traversal:** Uses native `find -print0` parsing to cleanly handle arbitrary spaces, trailing newlines, or unusual characters in file paths.
- **Safe Trashing:** Moves targeted files safely to the user's native Trash (`~/.Trash/`) instead of executing an irreversible `rm -rf`.

---

## Installation

1. Copy the script content into a file named `AppCleaner.sh`.
2. Make the script executable:
   ```bash
   chmod +x AppCleaner.sh
Usage
Bash
./AppCleaner.sh -p "Application Name" [--dry-run]
Options
-p "Application Name"
The target application name you want to search for. Wrap the name in quotes if it contains spaces. The script automatically checks for space-separated and space-collapsed variants.
--dry-run
(Optional) Simulates the process. Scans the file system and calculates the total footprint, but prints what would happen instead of moving items to the Trash.
Examples
1. Simulating a Deletion (Safe Mode)
To see every log, cache, and application support directory associated with "Mullvad Browser" without deleting anything:
Bash
./AppCleaner.sh -p "Mullvad Browser" --dry-run
Example Output:
Plaintext
Searching for application: Mullvad Browser
Found application:
  /Applications/Mullvad Browser.app

Scanning filesystem...

=========================================
Items found: 5
=========================================

114M       /Applications/Mullvad Browser.app
12K        /Users/username/Library/Application Support/Mullvad Browser
4.0K       /Users/username/Library/Preferences/net.mullvad.browser.plist
512K       /Users/username/Library/Caches/MullvadBrowser
8.0K       /Users/username/Library/Logs/Mullvad Browser

Approximate total size: 114.53 MB

Proceed with deletion? [y/N]
2. Performing an Uninstall
To find and move all components to the Trash:
Bash
./AppCleaner.sh -p "Mullvad Browser"
After confirming y at the prompt, all items will be securely relocated to your Trash bin.
Targeted Scan Locations
The script safely checks both User (~/Library) and System (/Library) frameworks across 3 levels of directory depth for the following scopes:
Application Support directories
Cache stores
Application Preferences (.plist files)
Log outputs
App Sandboxes (Containers)
Saved Application States
WebKit data & HTTP Storages
Launch Agents and Daemons
Safety Controls
Trash Integration: Unlike destructive uninstall tools that run rm -rf, this script uses mv to redirect items to your ~/.Trash. If you make a mistake, open your Trash can and pull the file back out.
Confirmation Prompt: The script will explicitly ask you to confirm (y/N) before running any moves, ensuring you can review the file manifest first.
