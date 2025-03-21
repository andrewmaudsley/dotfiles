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

# Function to set the current step
set_step() {
  CURRENT_STEP="$1"
  echo "Step: $CURRENT_STEP"
}

# Function to maintain sudo access
maintain_sudo() {
  while true; do
    sudo -v
    sleep 60
  done
}

# Function to cleanup sudo
cleanup_sudo() {
  set_step "Cleaning up administrator privileges"
  
  # If no sudo process is running, nothing to do
  if [ -z "$SUDO_PID" ]; then
    echo "No administrator privileges process to clean up"
    return 0
  fi
  
  # Kill the sudo maintenance process first
  if ! kill $SUDO_PID 2>/dev/null; then
    echo "Error: Failed to kill sudo maintenance process" >&2
    return $E_SUDO
  fi
  SUDO_PID=""
  echo "Administrator privileges cleaned up successfully"
  return 0
}

# Function to ensure sudo access
ensure_sudo() {
  set_step "Requesting administrator privileges"
  
  # Check if we already have sudo access
  if check_sudo_access; then
    echo "Administrator privileges already available"
    return 0
  fi
  
  # Request sudo access with a helpful message
  if ! sudo -p "Please enter your password to continue with the installation: " -v; then
    echo "Error: Failed to obtain administrator privileges" >&2
    echo "Please ensure you have sudo access and try again." >&2
    return $E_SUDO
  fi
  
  # Verify sudo access was obtained
  if ! check_sudo_access; then
    echo "Error: Failed to verify administrator privileges" >&2
    return $E_SUDO
  fi
  
  # Start background process to maintain sudo access
  maintain_sudo &
  SUDO_PID=$!
  
  echo "Administrator privileges obtained and verified successfully"
  return 0
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

# Function to validate directory
validate_directory() {
  local dir="$1"
  
  # Check if directory exists
  if [ -d "$dir" ]; then
    echo "Directory $dir exists"
    return 0
  fi
  
  # Try to create directory
  echo "Creating directory $dir..."
  if ! mkdir -p "$dir"; then
    echo "Error: Failed to create directory $dir" >&2
    return $E_DIRECTORY
  fi
  
  echo "Directory $dir created successfully"
  return 0
}

# Function to get installation directory
get_install_directory() {
  local default_dir="$1"
  local install_dir=""
  
  # If an argument was provided, use that
  if [ $# -gt 1 ]; then
    install_dir="$2"
  else
    install_dir="$default_dir"
  fi
  
  # Validate the directory
  validate_directory "$install_dir"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to validate installation directory" >&2
    return $E_DIRECTORY
  fi
  
  # Return the validated directory
  echo "$install_dir"
  return 0
}

# Function to handle termination signals
handle_termination() {
  echo "Received termination signal. Cleaning up..." >&2
  cleanup_sudo
  exit 0
}

# Function to install Xcode Command Line Tools
install_xcode_tools() {
  set_step "Installing Xcode Command Line Tools"
  
  if ! xcode-select -p &> /dev/null; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install || {
       echo "Error: Failed to install Xcode Command Line Tools"
       return $E_XCODE
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
  
  return 0
}

# Function to clone dotfiles repository
clone_dotfiles() {
  local install_dir="$1"
  set_step "Cloning dotfiles repository to $install_dir"
  
  if [ -d "$install_dir" ]; then
    if [ -d "$install_dir/.git" ]; then
      echo "dotfiles repo already exists at $install_dir"
    else
      echo "Error: Directory '$install_dir' exists but is not a git repository" >&2
      return $E_CLONE
    fi
  else
    echo "Cloning dotfiles repo to $install_dir..."
    if ! git clone https://github.com/andrewmaudsley/dotfiles.git "$install_dir"; then
      echo "Error: Failed to clone dotfiles repo" >&2
      return $E_CLONE
    fi
    echo "dotfiles repo cloned successfully"
  fi
  
  # Change to the dotfiles directory
  if ! cd "$install_dir"; then
    echo "Error: Failed to change to dotfiles directory" >&2
    return $E_DIRECTORY
  fi
  echo "Changed to dotfiles directory: $install_dir"
  
  return 0
}

# Function to install Homebrew
install_homebrew() {
  set_step "Installing and configuring Homebrew"
  
  if command -v brew &> /dev/null; then
    echo "Homebrew is already installed"
  else
    echo "Installing Homebrew..."
    
    # Download and run the install script
    if ! NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"; then
      echo "Error: Failed to install Homebrew" >&2
      echo "Please check the error messages above and try again" >&2
      return $E_HOMEBREW
    fi
    
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
      return $E_HOMEBREW
    fi
    
    # Verify Homebrew is working
    if ! brew --version &>/dev/null; then
      echo "Error: Homebrew installation verified but 'brew' command not working" >&2
      echo "Please try opening a new terminal and running 'brew --version'" >&2
      return $E_HOMEBREW
    fi
    
    echo "Homebrew installed successfully"
  fi
  
  # Update Homebrew
  echo "Updating Homebrew..."
  if ! brew update; then
    echo "Error: Failed to update Homebrew" >&2
    echo "You may want to run 'brew update' manually later" >&2
  fi
  
  return 0
}

# Function to install packages from Brewfile
install_packages() {
  set_step "Installing packages from Brewfile"
  
  if [ ! -f "Brewfile" ]; then
    echo "Error: Brewfile not found in current directory" >&2
    return $E_PACKAGES
  fi

  echo "Installing packages from Brewfile..."
  if ! brew bundle; then
    echo "Error: Failed to install packages from Brewfile" >&2
    return $E_PACKAGES
  fi
  echo "Packages installed successfully"
  
  return 0
}

# Function to cleanup after installation
cleanup() {
  set_step "Running cleanup tasks"
  local cleanup_failed=0
  
  # Cache brew paths while we still have sudo
  local brew_cache
  brew_cache="$(brew --cache)"
  
  # Run Homebrew cleanup tasks first while we still have sudo
  echo "Cleaning up Homebrew..."
  brew cleanup || cleanup_failed=1
  brew cleanup --prune=all || cleanup_failed=1
  
  # Now clean up sudo since we don't need it anymore
  cleanup_sudo
  
  # Remove Homebrew cache without sudo (if it exists)
  if [ -n "$brew_cache" ] && [ -d "$brew_cache" ]; then
    echo "Removing Homebrew cache..."
    rm -rf "$brew_cache" || cleanup_failed=1
  fi
  
  if [ $cleanup_failed -eq 1 ]; then
    echo "Warning: Some cleanup steps failed, but continuing..."
  else
    echo "Cleanup complete"
  fi
  
  return 0
}

# Main installation function
install_dotfiles() {
  local install_dir="$1"
  set_step "Initializing dotfiles installation"
  
  # Ensure we have sudo access before proceeding
  ensure_sudo || return $?
  
  # Install Xcode Command Line Tools if needed
  install_xcode_tools || return $?
  
  # Clone dotfiles repository
  clone_dotfiles "$install_dir" || return $?
  
  # Install and configure Homebrew
  install_homebrew || return $?
  
  # Install packages from Brewfile
  install_packages || return $?
  
  # Run cleanup
  cleanup
  
  # Mark script as finished successfully
  SCRIPT_FINISHED=true
  
  echo "dotfiles installation completed successfully!"
  return 0
}

# Set up traps
trap 'handle_error ${LINENO}' ERR
trap 'handle_termination' INT TERM HUP QUIT

# Get and validate installation directory
set_step "Validating installation directory"
INSTALL_DIR=$(get_install_directory "$HOME/.dotfiles")
[ $? -eq 0 ] || exit $E_DIRECTORY

# Run installation
install_dotfiles "$INSTALL_DIR"
exit $?
