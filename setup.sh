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

copy_examples() {
  echo "Copying examples"

  # ssh
  ssh_dir=ssh/.ssh
  echo "Checking for $ssh_dir/config"
  if [ -f $ssh_dir/config ]
  then 
    echo "Existing ssh config found"
  else
    cp $ssh_dir/config.example $ssh_dir/config 
    echo "Created blank ssh config from example"
  fi
}

install_dotfiles() {
  if [ -x "$(command -v stow)" ]
  then
    echo "Installing dotfiles with GNU Stow"
    # Explicitly set target & ignore options here
    # instead of in buggy .stowrc or .stow-local-ignore
    stow -t $HOME zsh
    stow -t $HOME gpg
    stow -t $HOME --ignore config.example ssh
    echo "dotfiles installed"
  else
    echo "Stow not installed - unable to install dotfiles"
  fi
}

echo "Setup started"
set_default_shell "zsh"
install_homebrew
install_homebrew_packages
copy_examples
install_dotfiles
echo "Setup finished"
echo "Please exit and start a new session for all changes to take effect"
