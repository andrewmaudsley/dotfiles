#!/usr/bin/env bash
set -euo pipefail

install_xcode_command_line_tools() {
  if xcode-select -p >/dev/null 2>&1; then
    echo "Xcode Command Line Tools already installed."
    return 0
  fi

  # Perform an unattended install using softwareupdate
  echo "Starting installation of Xcode Command Line Tools..."

  # Create install-on-demand placeholder file
  local placeholder="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
  sudo /usr/bin/touch "$placeholder" || true

  cleanup_placeholder() {
    sudo rm -f "$placeholder" || true
  }

  error_and_cleanup() {
    cleanup_placeholder
    echo "Error: $1" >&2
    exit 1
  } 

  # Find the correct label for Command Line Tools (this could change in future)
  local label
  label=$(softwareupdate -l 2>&1 \
    | awk -F": " '/Label: / && /Command Line (Developer|Tools)/ {print $2; exit}') || true

  if [[ -z "${label:-}" ]]; then
    error_and_cleanup "Could not find Command Line Tools in software update catalog."
  fi

  echo "Installing: $label"

  if ! sudo softwareupdate -i "$label" --verbose; then
    error_and_cleanup "Could not install '$label' via softwareupdate."
  fi

  # Ensure xcode-select points to the install path
  if [[ -d "/Library/Developer/CommandLineTools" ]]; then
    sudo xcode-select --switch /Library/Developer/CommandLineTools >/dev/null 2>&1 || true
  fi

  # Verify installation
  if xcode-select -p >/dev/null 2>&1; then
    cleanup_placeholder
    echo "Xcode Command Line Tools installation completed."
    return 0
  else
    error_and_cleanup "Xcode Command Line Tools not installed successfully."
  fi
}

platform="$(uname -s)"

if [[ "$platform" == "Darwin" ]]; then
  install_xcode_command_line_tools
else
  echo "Error: This script is for macOS. $platform is not supported."
  exit 1
fi
