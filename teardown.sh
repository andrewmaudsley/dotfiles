#!/bin/zsh

uninstall_homebrew() {
  if [ -x "$(command -v brew)" ]
  then
    echo "Uninstalling Homebrew"
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall)"
    echo "Homebrew uninstalled"
  else
    echo "Homebrew not installed"
  fi
}

echo "Teardown started"
uninstall_homebrew
echo "Teardown finished"
