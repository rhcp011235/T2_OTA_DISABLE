#!/bin/bash
# Disable / Enable macOS OTA Updates
# Intel x86_64 compatible
# Must be run as root

set -e

BIN_NAME="Disable_OTA_MACOS"

# -----------------------------
# Binary name enforcement
# -----------------------------
SCRIPT_NAME="$(basename "$0")"
if [[ "$SCRIPT_NAME" != "$BIN_NAME" ]]; then
  echo "[-] Script must be named: $BIN_NAME"
  exit 1
fi

# -----------------------------
# Root check
# -----------------------------
if [[ "$(id -u)" -ne 0 ]]; then
  echo "[-] Must be run as root"
  exit 1
fi

# -----------------------------
# OTA plist locations
# -----------------------------
PLISTS=(
  "/Library/Preferences/com.apple.SoftwareUpdate.plist"
  "/Library/Preferences/com.apple.commerce.plist"
  "/Library/Managed Preferences/com.apple.SoftwareUpdate.plist"
  "/var/db/softwareupdate/journal.plist"
)

# -----------------------------
# Disable OTA
# -----------------------------
disable_ota() {
  echo "[+] Disabling OTA updates"

  for plist in "${PLISTS[@]}"; do
    echo "[+] Writing $plist"

    /usr/bin/defaults write "$plist" AutomaticCheckEnabled -bool false
    /usr/bin/defaults write "$plist" AutomaticDownload -bool false
    /usr/bin/defaults write "$plist" CriticalUpdateInstall -bool false
    /usr/bin/defaults write "$plist" ConfigDataInstall -bool false
    /usr/bin/defaults write "$plist" AutoUpdate -bool false
    /usr/bin/defaults write "$plist" AutoUpdateRestartRequired -bool false
    /usr/bin/defaults write "$plist" ScheduleFrequency -int 0
  done

  echo "[+] Killing software update services"
  killall -9 softwareupdated 2>/dev/null || true
  killall -9 com.apple.MobileSoftwareUpdate 2>/dev/null || true

  echo "[+] Removing cached updates"
  rm -rf /Library/Updates/* || true
  rm -rf /var/db/softwareupdate/* || true

  echo "[+] Disabling softwareupdate daemon"
  launchctl unload -w /System/Library/LaunchDaemons/com.apple.softwareupdated.plist

  echo "[✓] OTA updates DISABLED"
}

# -----------------------------
# Enable OTA
# -----------------------------
enable_ota() {
  echo "[+] Re-enabling OTA updates"

  for plist in "${PLISTS[@]}"; do
    rm -f "$plist"
  done

  echo "[+] Restarting softwareupdate daemon"
  launchctl kickstart -k system/com.apple.softwareupdated

  echo "[✓] OTA updates ENABLED"
}

# -----------------------------
# Menu
# -----------------------------
echo
echo "Disable macOS OTA Updates"
echo "1) Disable OTA"
echo "2) Enable OTA"
echo "3) Exit"
echo

read -p "> " choice

case "$choice" in
  1) disable_ota ;;
  2) enable_ota ;;
  *) echo "Exiting" ;;
esac
