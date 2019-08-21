#!/bin/bash

# Get the directory the script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

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
    brew update
    brew bundle
    echo "Homebrew packages installed"
  else
    echo "Homebrew not installed"
  fi
}

install_nvm_and_node() {
  echo "Installing nvm"
  export NVM_DIR="$HOME/.nvm" && (
    git clone https://github.com/creationix/nvm.git "$NVM_DIR"
    cd "$NVM_DIR"
    git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
  ) && \. "$NVM_DIR/nvm.sh"
  echo "Installing latest Node.js release"
  nvm install node
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

  echo "Checking for user.ini used by grip"
  if [ -f grip/user.ini ]
  then
    echo "Existing user.ini found"
  else
    cp grip/user.ini.example grip/user.ini
    echo "Created user.ini from example"
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
    stow -t $HOME tmux
    stow -t $HOME vim
    stow -t $HOME ack
    stow -t $HOME/.grip --ignore user.ini.example grip
    echo "dotfiles installed"
  else
    echo "Stow not installed - unable to install dotfiles"
  fi
}

install_vundle_and_plugins() {
  echo "Installing Solarized Vim Colorscheme"
  if ! [ -d ~/.vim/colors ]
  then
    mkdir ~/.vim/colors
  fi
  if curl -o ~/.vim/colors/solarized.vim https://raw.githubusercontent.com/altercation/vim-colors-solarized/master/colors/solarized.vim
  then
    echo "Done"
  else
    echo "Failed"
  fi
  echo "Installing Vundle"
  if git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
  then
    echo "Vundle installed"
  else
    echo "Could not install Vundle"
  fi
  echo "Installing Plugins"
  if vim +PluginInstall +qall
  then
    echo "Plugins Installed"
    echo "Compiling YouCompleteMe"
    ~/.vim/bundle/YouCompleteMe/install.py --ts-completer
    echo "Compiling Command-T"
    cd ~/.vim/bundle/command-t/ruby/command-t/ext/command-t
    /usr/local/opt/ruby/bin/ruby extconf.rb
    make clean
    make
    cd $DIR
  else
    echo "Could not install plugins"
  fi
}

setup_font() {
  mkdir ~/Library/Fonts/SFMono
  cp /Applications/Utilities/Terminal.app/Contents/Resources/Fonts/* ~/Library/Fonts/SFMono
  echo "SF Mono font has been setup"
}

setup_iterm() {
  echo "Setting up iTerm"
  if defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string $DIR &&
  defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true
  then
    echo "Done"
  else
    echo "Unable to setup iTerm"
  fi
}

install_oh_my_zsh() {
  # Install manually to prevent addition of default .zshrc
  echo "Installing Oh-My-Zsh"
  if git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
  then
    echo "Installed Oh-My-Zsh"
  else
    echo "Unable to install Oh-My-Zsh"
  fi
}

setup_zsh() {
  # Use Zsh installed via Homebrew
  zsh_path="/usr/local/bin/zsh"
  if ! grep $zsh_path /etc/shells
  then
    echo "Adding Zsh installed via Homebrew to /etc/shells"
    echo $zsh_path | sudo tee -a /etc/shells
  fi
  set_default_shell $zsh_path
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

echo "Setup started"
install_homebrew
install_homebrew_packages
install_nvm_and_node
copy_examples
install_dotfiles
install_vundle_and_plugins
setup_font
setup_iterm
install_oh_my_zsh
setup_zsh
echo "Setup finished"
echo "Please exit and start a new session for all changes to take effect"
