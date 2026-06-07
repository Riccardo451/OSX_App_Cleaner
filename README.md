# 🧹 AppCleaner.sh

[![Platform: macOS](https://img.shields.io/badge/platform-macOS-apple.svg)](https://www.apple.com/macos/)
[![Shell: Bash 3.2+](https://img.shields.io/badge/shell-Bash%203.2%2B-blue.svg)](https://www.gnu.org/software/bash/)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](https://opensource.org/licenses/MIT)

A lightweight, robust, and safe shell script designed to completely uninstall macOS applications. It systematically sweeps away leftover configuration files, caches, logs, and related system data that standard drag-and-drop uninstalls leave behind.

Engineered specifically for full compatibility with native macOS environment constraints (including legacy **Bash 3.2**) while adhering to strict runtime safety configurations (`set -euo pipefail`).

---

## ✨ Features

* 🔍 **Dual-Layer App Detection** Leverages native macOS Spotlight (`mdfind`) for instantaneous discovery, automatically falling back to deep filesystem directory scanning if Spotlight indexing is disabled.
* 🧠 **Smart Matching Engine** Maximizes cleanup coverage by cross-referencing files using three independent vectors:
    * The original application name.
    * A space-stripped variant (e.g., matching both `Mullvad Browser` and `MullvadBrowser`).
    * The app's unique Bundle Identifier (`CFBundleIdentifier`) extracted directly from its `Info.plist`.
* 🛡️ **Dry-Run Mode** Preview the absolute path and storage impact of all targeted items safely without making a single modification to the system.
* 💾 **Safe File Traversal** Implements strict null-delimited processing (`find -print0`) to flawlessly handle paths containing spaces, trailing newlines, or unusual characters.
* 🗑️ **Trash-First Philosophy** Zero risk of catastrophic accidental loss. Files are safely relocated to the native user Trash (`~/.Trash/`) instead of being permanently erased with destructive `rm -rf` commands.

---

## 🚀 Installation & Setup

1. Save the script contents into a file named `AppCleaner.sh`.
2. Open your terminal and grant execution permissions:

```bash
chmod +x AppCleaner.sh
🛠️ Usage & Options
Bash
./AppCleaner.sh -p "Application Name" [--dry-run]
Command Flags
Flag	Argument	Description
-p	"Application Name"	Required. Specifies the target application. Wrap in quotes if the name contains spaces. The engine will automatically evaluate multiple name variations.
--dry-run	None	Optional. Simulates the removal. It scans the filesystem, calculates the disk footprint, and stops at the prompt without moving any files.
📖 Examples
1. Previewing Leftovers (Dry-Run Mode)
Bash
./AppCleaner.sh -p "Mullvad Browser" --dry-run
Console Output:
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
2. Performing a Complete Uninstall
Bash
./AppCleaner.sh -p "Mullvad Browser"
💡 Note: After reviewing the detected assets, type y or yes at the prompt. All tracked resources will be immediately moved to your Trash.
📂 Target Scan Locations
The engine performs targeted, depth-limited sweeps across both User-level (~/) and System-level (/) asset frameworks:
/Applications & ~/Applications (.app bundles)
~/Library/Application Support & /Library/Application Support
~/Library/Caches & /Library/Preferences
~/Library/Logs & /Library/Logs
~/Library/Containers (App Sandboxes)
~/Library/Saved Application State
~/Library/WebKit & ~/Library/HTTPStorages
~/Library/Group Containers
/Library/LaunchAgents & /Library/LaunchDaemons
/Library/PrivilegedHelperTools
🔒 Safety Controls
Reversible Trashing: Because files are relocated to ~/.Trash/ via mv, any accidental flags can be instantly restored using the native macOS "Put Back" feature in the Trash bin.
Explicit Confirmation Guardrails: Destructive execution paths are entirely blocked until the script prints the exact file manifest, totals the collective disk space usage, and receives an explicit y/yes confirmation from the user.
