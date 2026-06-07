# AppCleaner.sh

A lightweight, robust, and safe shell script for completely uninstalling macOS applications and removing leftover configuration files, caches, logs, and related system data.

Designed for compatibility with the native macOS Bash 3.2 environment and strict runtime settings (`set -euo pipefail`).

---

## Features

- **Robust app detection**  
  Uses macOS Spotlight (`mdfind`) for fast discovery, with fallback to deep filesystem scanning if Spotlight indexing is unavailable.

- **Smart matching system**  
  Finds leftovers using:
  - Original application name
  - Space-stripped variant (e.g., `Mullvad Browser` → `MullvadBrowser`)
  - App bundle identifier (`CFBundleIdentifier`)

- **Dry-run mode**  
  Preview all files that would be affected without modifying the system.

- **Safe file traversal**  
  Uses `find -print0` to correctly handle spaces, newlines, and special characters in file paths.

- **Safe deletion approach**  
  Moves files to the user Trash (`~/.Trash/`) instead of permanently deleting them with `rm -rf`.

---

## Installation

1. Copy the script into a file named `AppCleaner.sh`

2. Make it executable:
```bash
chmod +x AppCleaner.sh

Usage
./AppCleaner.sh -p "Application Name" [--dry-run]
Options
-p "Application Name"
Specifies the target application to uninstall.
Use quotes if the name contains spaces
The script automatically tries multiple name variations
--dry-run (optional)
Simulates the uninstall process without making changes:
Scans filesystem
Lists detected files
Calculates total size
Prompts for confirmation without moving anything
Examples
Dry Run (Safe Mode)
./AppCleaner.sh -p "Mullvad Browser" --dry-run
Example output:
Searching for application: Mullvad Browser
Found application:
  /Applications/Mullvad Browser.app

Scanning filesystem...

=========================================
Items found: 5
=========================================

114M  /Applications/Mullvad Browser.app
12K   /Users/username/Library/Application Support/Mullvad Browser
4.0K  /Users/username/Library/Preferences/net.mullvad.browser.plist
512K  /Users/username/Library/Caches/MullvadBrowser
8.0K  /Users/username/Library/Logs/Mullvad Browser

Approximate total size: 114.53 MB

Proceed with deletion? [y/N]
Full Uninstall
./AppCleaner.sh -p "Mullvad Browser"
After confirmation (y), all detected files are safely moved to the Trash.
Targeted Scan Locations
The script searches both user and system-level locations:
/Applications
~/Applications
~/Library/Application Support
~/Library/Caches
~/Library/Preferences
~/Library/Logs
~/Library/Containers
~/Library/Saved Application State
/Library/Application Support
/Library/LaunchAgents
/Library/LaunchDaemons
WebKit and HTTP storage directories
Safety Features
Trash-based removal
Instead of permanent deletion, files are moved to:
~/.Trash/
This allows easy recovery if something is removed accidentally.
Confirmation prompt
Before any destructive action:
Full list of targets is displayed
Total disk usage is calculated
User must explicitly confirm with y
