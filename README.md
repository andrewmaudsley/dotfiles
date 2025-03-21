# dotfiles

This dotfiles  repo is used to setup and manage a macOS based software development environment, primarily for the development of [TypeScript](https://www.typescriptlang.org) applications.

Learn more about dotfiles with an unofficial guide from GitHub at [dotfiles.github.io](https://dotfiles.github.io).

## Usage

Use 'as is' or as inspiration for your own dotfiles.  

Intended for installation on a fresh install of macOS, as the principal method of environment setup and ongoing management. However, features can be integrated with, or run alongside, an existing dotfiles setup with modification.  

Before installing on your main development system, running a trial on a fresh install of macOS is recommended, for example using a virtual machine. Reading the [install script](./scripts/install.sh) and backing up any existing configuration is also recommended prior to use.  

Note that this is a perpetual work in progress and is developed to meet the requirements and taste of the author [Andrew Maudsley](https://www.andrewmaudsley.com), as such no warranty is provided (see [LICENSE](./LICENSE)).

Feedback or suggestions are welcome, please raise an issue or submit a pull request.

## Prerequisites

* macOS - tested with Sequoia 15.3.1

## Installation

On first run, the install script will perform the initial installation and environment setup. Once complete, subsequent runs allow the environment to be updated.

Running the install script will:

* Install Xcode Command Line Tools if not present
* Clone this repo
* Install the [Homebrew](https://brew.sh) package manager
* Install packages and applications ([casks](https://github.com/Homebrew/homebrew-cask)) listed in the [Brewfile](./Brewfile) using [brew bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile)
* Run cleanup   

Modern versions of macOS come with [curl](https://github.com/curl/curl) installed by default. This can be used to download and execute the install script using the following command:

```sh
curl -fsSL https://raw.githubusercontent.com/andrewmaudsley/dotfiles/main/scripts/install.sh | bash
```