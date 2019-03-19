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

  # git 
  echo "Checking for gitconfig user switch include"
  if [ -f git/.gitconfig_user_switch.inc ]
  then 
    echo "Existing gitconfig user switch include found"
  else
    cp git/.gitconfig_user_switch.inc.example git/.gitconfig_user_switch.inc
    echo "Created blank git config user switch include from example"
  fi

  echo "Checking for gitconfig user include"
  if [ -f git/.gitconfig_users/.user.inc ]
  then 
    echo "Existing gitconfig user include found"
  else
    cp git/.gitconfig_users/.user.inc.example git/.gitconfig_users/.user.inc
    echo "Created blank git config user include from example"
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
    stow -t $HOME --ignore .gitconfig_user_switch.inc.example --ignore .user.inc.example git
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
