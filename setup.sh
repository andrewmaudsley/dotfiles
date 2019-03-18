#!/bin/zsh

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
install_homebrew
install_homebrew_packages
echo "Setup finished"
