# dotfiles

This dotfiles repo is used to setup and manage a macOS based software development environment, primarily for the development of [TypeScript](https://www.typescriptlang.org) applications and [Python](https://www.python.org) applications.

Learn more about dotfiles by reading the unofficial guide from GitHub at [dotfiles.github.io](https://dotfiles.github.io).

## Usage

Use 'as is' or as inspiration for your own dotfiles.

Intended for use with a fresh install of macOS, as the principal method of environment setup and ongoing management. However, features could be integrated with, or run alongside, an existing dotfiles solution with modification.

Before running the setup on your main development system, it is recommended to follow these steps:

- Run a trial on a fresh install of macOS, for example using a virtual machine
- Read the [setup script](./setup.sh) to become familiar with the setup process
- Back up any existing configuration before running the setup

Note that this is a perpetual work in progress and is developed to meet the requirements and taste of the author [Andrew Maudsley](https://www.andrewmaudsley.com), as such no warranty is provided (see [LICENSE](./LICENSE)).

Feedback or suggestions are welcome, please raise an issue or submit a pull request.

## Setup

To setup the environment, run the following shell command:

```sh
curl -fsSL https://raw.githubusercontent.com/andrewmaudsley/dotfiles/main/setup.sh | bash
```
