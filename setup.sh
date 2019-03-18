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

echo "Setup started"
install_homebrew
echo "Setup finished"
