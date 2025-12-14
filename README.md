# Disable_OTA_MACOS

Special thanks to @int1h for the help to get this properly reversed. 

A small, root-only Bash utility that disables and re-enables macOS software update (OTA) behavior by writing preference keys, clearing update caches, and stopping the `softwareupdated` LaunchDaemon.

I have also included a Objective C version:

```
clang -arch x86_64 \
  -fobjc-arc \
  -x objective-c++ disota2.mm \
  -framework Foundation \
  -framework CoreFoundation \
  -lc++ \
  -o Disable_OTA_MACOS
```

This project is intentionally minimal. It exists to do one job reliably and be easy to audit.

## What this does

When you choose "Disable OTA", the script performs the following actions:

1. Writes preference keys that disable automatic update checks and downloads to several common Software Update preference locations.
2. Terminates any currently running update-related processes so the changes take effect immediately.
3. Removes common Software Update caches and staged update content.
4. Unloads the `com.apple.softwareupdated` LaunchDaemon in a persistent way so it does not restart automatically after reboot.

When you choose "Enable OTA", the script:

1. Deletes the preference plists it wrote/modified so macOS can regenerate defaults.
2. Restarts the `softwareupdated` daemon.

## What this does not do

- It does not bypass or modify SIP (System Integrity Protection).
- It does not patch system binaries.
- It does not permanently survive major macOS upgrades (upgrades can re-enable software update components).
- It does not selectively allow only security updates. Disabling here is broad.

## Requirements

- macOS
- Root access (must run with `sudo`)
- `/bin/bash`
- `defaults`, `launchctl`, `killall`, `rm` (all included on macOS)

## Files

The script is intended to be saved with a specific filename:

- `Disable_OTA_MACOS`

The name matters because the script enforces it at runtime. If you rename it, it will exit immediately.

## Installation

1. Save the script as a file named `Disable_OTA_MACOS`:

   ```bash
   nano Disable_OTA_MACOS
