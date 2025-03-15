# dotfiles

This [dotfiles](https://dotfiles.github.io) repo is used to setup and manage a macOS based software development environment, primarily for the development of [TypeScript](https://www.typescriptlang.org) and JavaScript applications.

## Usage

Use 'as is' or as inspiration for your own dotfiles.  

Intended for installation on a fresh install of macOS and as the principal method of environment setup and ongoing management. However, features could be incorporated into, or run alongside, an existing dotfiles setup with modification.  

Before installing on your main development system, it's recommended to run a trial on a fresh install of macOS, for example using a virtual machine. Backing up any existing configuration prior to use is also recommended.  

Note that this is a perpetual work in progress and is developed to meet the requirements and taste of the author [Andrew Maudsley](https://www.andrewmaudsley.com), as such no warranty is provided (see [LICENSE](./LICENSE)).

Feedback or suggestions are welcome, please raise an issue or submit a pull request.

## Prerequisites

* macOS - tested with Sequoia 15.3.1

## Installation

The installation script will perform the initial installation and setup. Once complete, subsequent runs allow the environment to be updated.

Running the install script will:

* Install Xcode Command Line Tools
* Clone this repo
* Install the [Homebrew](https://brew.sh) package manager
* Install packages and applications ([casks](https://github.com/Homebrew/homebrew-cask)) listed in the [Brewfile](./Brewfile) using [Homebrew Bundle](https://github.com/Homebrew/homebrew-bundle)
* Run cleanup   

Modern versions of macOS come with [curl](https://github.com/curl/curl) installed by default. This can be used to run the install script using the following command:

```sh
curl -fsSL https://raw.githubusercontent.com/andrewmaudsley/dotfiles/main/scripts/install.sh | bash
```