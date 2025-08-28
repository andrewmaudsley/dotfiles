#!/usr/bin/env bash
set -euo pipefail

install_xcode_command_line_tools() {
  if xcode-select -p >/dev/null 2>&1; then
    echo "Xcode Command Line Tools already installed."
    return 0
  fi

  echo "Starting installation of Xcode Command Line Tools..."
  # Trigger the Xcode install prompt dialog
  if ! xcode-select --install >/dev/null 2>&1; then
    echo "Waiting for Xcode Command Line Tools installation to complete..."
  fi

  # Wait for installation to complete
  local timeout_minutes=30
  local timeout=$((timeout_minutes * 60))
  local interval=20
  local elapsed=0
  while ! xcode-select -p >/dev/null 2>&1; do
    if (( elapsed >= timeout )); then
      echo "Error: Xcode Command Line Tools installation timed out after ${timeout_minutes} minutes." >&2
      echo "To install manually run: xcode-select --install" >&2
      return 1
    fi
    sleep "$interval"
    elapsed=$((elapsed + interval))
  done

  echo "Xcode Command Line Tools installation completed."
}

platform="$(uname -s)"

if [[ "$platform" == "Darwin" ]]; then
  install_xcode_command_line_tools
else
  echo "Error: This script is for macOS. $platform is not supported."
  exit 1
fi
