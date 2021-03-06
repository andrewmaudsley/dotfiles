#!/bin/bash

# Get the directory the script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

uninstall_dotfiles() {
  if [ -x "$(command -v stow)" ]
  then
    echo "Uninstalling dotfiles with GNU Stow"
    stow -D -t $HOME zsh
    stow -D -t $HOME gpg
    stow -D -t $HOME ssh
    stow -D -t $HOME git
    stow -D -t $HOME tmux
    stow -D -t $HOME vim
    echo "dotfiles uninstalled"
  else
    echo "Stow not installed - unable to uninstall dotfiles"
  fi
}

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

uninstall_vim_plugins() {
  if rm -rf ~/.vim/bundle/*
  then
    echo "Uninstalled Vim Plugins"
  else
    echo "Unable to uninstall Vim Plugins"
  fi
}

uninstall_nvm_and_node() {
  if rm -rf ~/.nvm/
  then
    echo "Removed nvm"
  else
    echo "Could not find nvm"
  fi
}

uninstall_oh_my_zsh() {
  rm -rf ~/.oh-my-zsh
  rm ~/.zcompdump-*
  echo "Uninstalled Oh-My-Zsh"
}

remove_font() {
  rm -rf ~/Library/Fonts/SFMono
  echo "Removed SF Mono font"
}

teardown_iterm() {
  echo "Tearing down iTerm"
  if defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool false &&
  rm ~/Library/Preferences/com.googlecode.iterm2.plist
  then
    echo "Done"
  else
    echo "Unable to teardown iTerm"
  fi
}

teardown_zsh() {
  # Remove Zsh installed via Homebrew from shells list
  echo "Removing Zsh installed via Homebrew from /etc/shells"
  # Empty arg required
  if sudo sed -i '' '\|/usr/local/bin/zsh|d' /etc/shells
  then
    echo "Removed"
  else
    echo "Failed"
  fi
  set_default_shell "/bin/bash"
}

set_default_shell() {
  shell_path=$1
  if chsh -s $shell_path
    then
      echo "Changed default shell to $shell_path"
    else
      echo "Unable to change default shell to $shell_path"
  fi
}

echo "Teardown started"
uninstall_dotfiles
uninstall_homebrew
uninstall_vim_plugins
uninstall_nvm_and_node
uninstall_oh_my_zsh
remove_font
teardown_iterm
teardown_zsh
echo "Teardown finished"
echo "Please exit and start a new session for all changes to take effect"
