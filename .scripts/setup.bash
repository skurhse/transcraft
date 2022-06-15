#!/usr/bin/env bash

# REQ: Installs dev tools on macOS Montery. <skr 2002-06-12>

set -o errexit
set -o noclobber
set -o noglob
set -o nounset
set -o pipefail
set -o xtrace

declare -A packages=(
    azure-cli
    bash
    github

)

brew update

for package in ${packages[@]}; do brew install $package; done

brew install azure-cli
brew install bash
brew install github
brew install --cask multipass

