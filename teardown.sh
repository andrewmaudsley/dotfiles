#!/bin/zsh

uninstall_dotfiles() {
  if [ -x "$(command -v stow)" ]
  then
    echo "Uninstalling dotfiles with GNU Stow"
    stow -D -t $HOME zsh
    stow -D -t $HOME gpg
    stow -D -t $HOME ssh
    stow -D -t $HOME git
    stow -D -t $HOME tmux
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

set_default_shell() {
  shell_name=$1
  if chsh -s /bin/$shell_name
  then
    echo "Changed default shell to $shell_name"
  else
    echo "Unable to change default shell to $shell_name"
  fi
}

uninstall_oh_my_zsh() {
  if rm -rf ~/.oh-my-zsh
  then
    echo "Uninstalled Oh-My-Zsh"
  fi
}

remove_font() {
  rm -rf ~/Library/Fonts/SFMono
  echo "Removed SF Mono font"
}

uninstall_iterm_profile() {
  if [ -f ~/Library/Application\ Support/iTerm2/DynamicProfiles/iterm-profile.json ]
  then
    rm ~/Library/Application\ Support/iTerm2/DynamicProfiles/iterm-profile.json
    echo "Removed iTerm profile"
  else
    echo "Could not find iTerm profile to remove"
  fi
}

echo "Teardown started"
uninstall_dotfiles
uninstall_homebrew
set_default_shell "bash"
uninstall_oh_my_zsh
remove_font
uninstall_iterm_profile
echo "Teardown finished"
echo "Please exit and start a new session for all changes to take effect"
