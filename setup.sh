#!/bin/zsh

set_default_shell() {
  shell_name=$1
  if chsh -s /bin/$shell_name
  then
    echo "Changed default shell to $shell_name"
  else
    echo "Unable to change default shell to $shell_name"
  fi
}

install_homebrew() {
  if [ -x "$(command -v brew)" ]
  then
    echo "Homebrew already installed"
  else
    echo "Installing Homebrew"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    echo "Homebrew installed"
  fi
}

install_homebrew_packages() {
  if [ -x "$(command -v brew)" ]
  then
    echo "Installing Homebrew packages"
    brew bundle
    echo "Homebrew packages installed"
  else
    echo "Homebrew not installed"
  fi
}

echo "Setup started"
set_default_shell "zsh"
install_homebrew
install_homebrew_packages
echo "Setup finished"
echo "Please exit and start a new session for all changes to take effect"
