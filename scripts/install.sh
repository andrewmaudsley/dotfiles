#!/bin/zsh

# Enable strict error handling
set -uo pipefail  # Removed -e as we'll handle it in the trap

# Define exit codes
readonly E_SUDO=1
readonly E_XCODE=2
readonly E_CLONE=3
readonly E_HOMEBREW=4
readonly E_PACKAGES=5
readonly E_DIRECTORY=6
readonly E_UNEXPECTED=99

# Current step tracking
CURRENT_STEP=""
SUDO_PID=""
SCRIPT_FINISHED=false

# Function to set current step
set_step() {
  CURRENT_STEP="$1"
  echo "Step: $1"
}

# Function to maintain sudo access
maintain_sudo() {
  while [ "$SCRIPT_FINISHED" = "false" ]; do
    # Check sudo access without prompting
    if ! check_sudo_access; then
      if ! sudo -p "Please enter your password to continue: " -v; then
        echo "Error: Failed to renew administrator privileges" >&2
        return $E_SUDO
      fi
      
      # Verify sudo access was renewed
      if ! check_sudo_access; then
        echo "Error: Failed to verify administrator privileges after renewal" >&2
        return $E_SUDO
      fi
    fi
    sleep 5  # Reduced sleep time to be more responsive to script completion
  done
}

# Function to cleanup sudo
cleanup_sudo() {
  if [ -n "$SUDO_PID" ]; then
    set_step "Cleaning up administrator privileges"
    SCRIPT_FINISHED=true  # Signal the maintain_sudo loop to stop
    wait $SUDO_PID 2>/dev/null || true
    SUDO_PID=""
  fi
}

# Error handler
handle_error() {
  local exit_code=$?
  local line_no=$1
  
  # Don't handle explicit exits with success or if script finished successfully
  if [ "$exit_code" -eq 0 ] || [ "$SCRIPT_FINISHED" = "true" ]; then
    exit 0
  fi
  
  # Clean up sudo if needed
  cleanup_sudo
  
  # Print error message with context
  echo "Error occurred in step: $CURRENT_STEP" >&2
  echo "Line $line_no: Exit code $exit_code" >&2
  
  # Don't treat process termination as error
  if [ "$exit_code" -eq 143 ]; then  # SIGTERM
    echo "Process terminated by user" >&2
    exit 0
  fi
  
  # Map known error codes to messages
  if [ "$exit_code" -ge "$E_SUDO" ] && [ "$exit_code" -le "$E_DIRECTORY" ]; then
    case $exit_code in
      $E_SUDO)
        echo "Failed to obtain or maintain administrator privileges" >&2
        ;;
      $E_XCODE)
        echo "Failed to install Xcode Command Line Tools" >&2
        ;;
      $E_CLONE)
        echo "Failed to clone dotfiles repository" >&2
        ;;
      $E_HOMEBREW)
        echo "Failed to install or configure Homebrew" >&2
        ;;
      $E_PACKAGES)
        echo "Failed to install packages from Brewfile" >&2
        ;;
      $E_DIRECTORY)
        echo "Failed to validate or create directory" >&2
        ;;
    esac
    exit "$exit_code"
  fi
  
  # Handle unexpected errors
  echo "An unexpected error occurred" >&2
  exit $E_UNEXPECTED
}

# Function to check if we have sudo access without a password
check_sudo_access() {
  sudo -n true 2>/dev/null
}

# Function to ensure sudo access
ensure_sudo() {
  set_step "Requesting administrator privileges"
  echo "This script requires administrator privileges to install and configure software."
  echo "You may be prompted for your password."
  
  # Clear any existing sudo tokens for safety
  sudo -k
  
  # Request sudo access with a helpful message
  if ! sudo -p "Please enter your password to continue with the installation: " -v; then
    echo "Error: Failed to obtain administrator privileges" >&2
    echo "Please ensure you have sudo access and try again." >&2
    exit $E_SUDO
  fi
  
  # Verify initial sudo access
  if ! check_sudo_access; then
    echo "Error: Failed to verify administrator privileges" >&2
    echo "Please ensure you have sudo access and try again." >&2
    exit $E_SUDO
  fi
  
  # Start background process to maintain sudo access
  maintain_sudo &
  SUDO_PID=$!
  
  # Set up cleanup trap for the sudo maintenance process
  trap cleanup_sudo EXIT INT TERM HUP QUIT
  
  echo "Administrator privileges obtained and verified successfully"
}

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
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" || {
      echo "Error: Failed to install Homebrew" >&2
      echo "Please check the error messages above and try again" >&2
      exit $E_HOMEBREW
    }
    
    # Add Homebrew to PATH based on architecture
    local brew_path=""
    if [[ "$(uname -m)" == "arm64" ]]; then
      brew_path="/opt/homebrew/bin/brew"
      (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> "$HOME/.zprofile"
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      brew_path="/usr/local/bin/brew"
      (echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >> "$HOME/.zprofile"
      eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    # Verify Homebrew executable exists
    if [ ! -x "$brew_path" ]; then
      echo "Error: Homebrew executable not found at $brew_path" >&2
      echo "Installation may have failed or PATH may not be set correctly" >&2
      exit $E_HOMEBREW
    fi
    
    # Verify Homebrew is working
    if ! brew --version &>/dev/null; then
      echo "Error: Homebrew installation verified but 'brew' command not working" >&2
      echo "Please try opening a new terminal and running 'brew --version'" >&2
      exit $E_HOMEBREW
    fi
    
    echo "Homebrew installed successfully"
  fi
  
  # Update Homebrew
  echo "Updating Homebrew..."
  if ! brew update; then
    echo "Error: Failed to update Homebrew" >&2
    echo "You may want to run 'brew update' manually later" >&2
  fi
}

# Function to install packages from Brewfile
install_packages() {
  set_step "Installing packages from Brewfile"
  
  if [ ! -f "Brewfile" ]; then
    echo "Error: Brewfile not found in current directory"
    exit $E_PACKAGES
  fi

  echo "Installing packages from Brewfile..."
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
  
  # Clean up sudo first to prevent hanging
  cleanup_sudo
  
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
  
  # Ensure we have sudo access before proceeding
  ensure_sudo
  
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
  
  # Mark script as finished successfully
  SCRIPT_FINISHED=true
  
  echo "dotfiles installation completed successfully!"
  exit 0
}

# Set up error trap with line number
trap 'handle_error ${LINENO}' ERR

# Get and validate installation directory
set_step "Validating installation directory"
INSTALL_DIR=$(get_install_directory "$HOME/.dotfiles")

# Run installation
install_dotfiles "$INSTALL_DIR"
