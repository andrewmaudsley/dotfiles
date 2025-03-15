#!/bin/zsh

# Enable strict error handling
set -uo pipefail  # Removed -e as we'll handle it in the trap

# Define exit codes
readonly E_XCODE=1
readonly E_CLONE=2
readonly E_HOMEBREW=3
readonly E_PACKAGES=4
readonly E_DIRECTORY=5
readonly E_UNEXPECTED=99

# Current step tracking
CURRENT_STEP=""

# Function to set current step
set_step() {
  CURRENT_STEP="$1"
}

# Error handler
handle_error() {
  local exit_code=$?
  local line_no=$1
  
  # Don't handle explicit exits with success
  if [ "$exit_code" -eq 0 ]; then
    exit 0
  fi
  
  echo "Error during step: ${CURRENT_STEP:-Unknown step}" >&2
  echo "Failed on line $line_no with exit code $exit_code" >&2
  
  # Preserve explicit error codes from functions
  if [ "$exit_code" -ge "$E_XCODE" ] && [ "$exit_code" -le "$E_DIRECTORY" ]; then
    exit "$exit_code"
  fi
  
  exit $E_UNEXPECTED
}

# Set up error trap with line number
trap 'handle_error ${LINENO}' ERR

# Function to validate directory
validate_directory() {
  local dir="$1"
  
  # Convert to absolute path if relative path provided
  case "$dir" in
    /*) ;; # Already absolute path
    *) dir="$PWD/$dir" ;;
  esac
  
  # Validate directory path
  if [[ "$dir" =~ [[:space:]] ]]; then
    echo "Error: Installation directory cannot contain spaces" >&2
    return 1
  fi
  
  # Validate parent directory exists and is writable
  local parent_dir
  parent_dir=$(dirname "$dir")
  if [ ! -d "$parent_dir" ]; then
    echo "Error: Parent directory '$parent_dir' does not exist" >&2
    return 1
  fi
  
  if [ ! -w "$parent_dir" ]; then
    echo "Error: Parent directory '$parent_dir' is not writable" >&2
    return 1
  fi
  
  # Additional validation for target directory
  if [ -e "$dir" ] && [ ! -d "$dir/.git" ]; then
    echo "Error: Target directory exists but is not a git repository" >&2
    return 1
  fi
  
  echo "$dir"
  return 0
}

# Function to get validated installation directory
get_install_directory() {
  local default_dir="${1:-$HOME/.dotfiles}"
  local install_dir
  
  while true; do
    read -p "Enter installation directory [$default_dir]: " install_dir
    install_dir="${install_dir:-$default_dir}"
    
    # Validate directory
    if VALIDATED_DIR=$(validate_directory "$install_dir"); then
      echo "$VALIDATED_DIR"
      return 0
    fi
  done
}

# Function to install Xcode Command Line Tools
install_xcode_tools() {
  set_step "Installing Xcode Command Line Tools"
  
  if ! xcode-select -p &> /dev/null; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install || {
      echo "Error: Failed to install Xcode Command Line Tools"
      exit $E_XCODE
    }
    # Wait for Xcode Command Line Tools to finish installing
    echo "Waiting for Xcode Command Line Tools installation to complete..."
    until xcode-select -p &> /dev/null; do
      sleep 5
    done
    echo "Xcode Command Line Tools installation complete"
  else
    echo "Xcode Command Line Tools already installed"
  fi
}

# Function to clone dotfiles repository
clone_dotfiles() {
  local install_dir="$1"
  set_step "Cloning dotfiles repository to $install_dir"
  
  if [ -d "$install_dir" ]; then
    if [ -d "$install_dir/.git" ]; then
      echo "dotfiles repo already exists at $install_dir"
    else
      echo "Error: Directory '$install_dir' exists but is not a git repository"
      exit $E_CLONE
    fi
  else
    echo "Cloning dotfiles repo to $install_dir..."
    git clone https://github.com/andrewmaudsley/dotfiles.git "$install_dir" || {
      echo "Error: Failed to clone dotfiles repo"
      exit $E_CLONE
    }
    echo "dotfiles repo cloned successfully"
  fi
  
  # Change to the dotfiles directory
  cd "$install_dir" || {
    echo "Error: Failed to change to dotfiles directory"
    exit $E_DIRECTORY
  }
  echo "Changed to dotfiles directory: $install_dir"
}

# Function to install Homebrew
install_homebrew() {
  set_step "Installing and configuring Homebrew"
  
  if command -v brew &> /dev/null; then
    echo "Homebrew is already installed"
  else
    echo "Installing Homebrew..."
    # Download and run the install script
    (yes "" | INTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)") || {
      echo "Error: Failed to install Homebrew"
      exit $E_HOMEBREW
    }
    
    # Add Homebrew to PATH
    if [[ "$(uname -m)" == "arm64" ]]; then
      # Apple Silicon path
      (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/$(whoami)/.zprofile
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      # Intel path
      (echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >> /Users/$(whoami)/.zprofile
      eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    echo "Homebrew installed successfully"
  fi
  
  # Update Homebrew
  echo "Updating Homebrew..."
  brew update || {
    echo "Error: Failed to update Homebrew"
    exit $E_HOMEBREW
  }
}

# Function to install packages from Brewfile
install_packages() {
  set_step "Installing packages from Brewfile"
  
  if [ ! -f "Brewfile" ]; then
    echo "Error: Brewfile not found in current directory"
    exit $E_PACKAGES
  fi

  echo "Installing packages from Brewfile..."
  # Install Homebrew Bundle
  brew tap Homebrew/bundle || {
    echo "Error: Failed to tap Homebrew/bundle"
    exit $E_PACKAGES
  }

  # Install packages from Brewfile
  brew bundle || {
    echo "Error: Failed to install packages from Brewfile"
    exit $E_PACKAGES
  }
  echo "Packages installed successfully"
}

# Function to cleanup after installation
cleanup() {
  set_step "Running cleanup tasks"
  
  echo "Running cleanup..."
  local cleanup_failed=0
  
  # Clean up Homebrew
  echo "Cleaning up Homebrew..."
  brew cleanup || {
    echo "Warning: Homebrew cleanup failed"
    cleanup_failed=1
  }
  
  # Remove Homebrew cache
  echo "Removing Homebrew cache..."
  rm -rf "$(brew --cache)" || {
    echo "Warning: Failed to remove Homebrew cache"
    cleanup_failed=1
  }
  
  # Clean up outdated versions
  echo "Removing outdated versions..."
  brew cleanup --prune=all || {
    echo "Warning: Failed to remove outdated versions"
    cleanup_failed=1
  }
  
  if [ $cleanup_failed -eq 1 ]; then
    echo "Warning: Some cleanup steps failed, but continuing..."
  else
    echo "Cleanup complete"
  fi
}

# Main installation function
install_dotfiles() {
  local install_dir="$1"
  set_step "Initializing dotfiles installation"
  
  # Install Xcode Command Line Tools if needed
  install_xcode_tools

  # Clone dotfiles repository
  clone_dotfiles "$install_dir"
  
  # Install and configure Homebrew
  install_homebrew
  
  # Install packages from Brewfile
  install_packages
  
  # Run cleanup
  cleanup
  
  set_step "Completing installation"
  echo "Installation complete! 🎉"
  return 0
}

# Get and validate installation directory
set_step "Validating installation directory"
INSTALL_DIR=$(get_install_directory "$HOME/.dotfiles")

# Run installation
install_dotfiles "$INSTALL_DIR"
exit $?
