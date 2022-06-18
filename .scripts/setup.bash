#!/usr/bin/env bash

# REQ: Installs dev tools on macOS Monterey. <skr 2002-06-15>

# TODO: Handle ~/.bash_profile setup. <>

set -o errexit
set -o noclobber
set -o noglob
set -o nounset
set -o pipefail
set -o xtrace

local=/usr/local
src=$local/bin
src=$local/src
sudo mkdir -p $src

 brew_formulae=(
  'azure-cli'
  'bash'
  'gh'
  'gnu-tar'
  'yq'
)

 brew_casks=(
  'multipass'
)

 launchpad_releases=(
  'cloud-init'
)

main() {
  update_brew
  install_brew_formulae
  install_brew_casks

  install_launchpad_releases
}

update_brew() {
  brew update
}

install_brew_formulae() {
  for formula in ${brew_ormulae[@]}
  do
    brew install $formula
  done
}

install_brew_casks() {
  for cask in ${brew_casks[@]}
  do
    brew install --cask $cask
  done
}

# TODO: Figure-out how to properly query for latest. <skr>
# Install to multipass virtual machine
install_launchpad_releases() {
  for release in "${launchpad_releases[@]}"
  do
    resource=$(
      curl -LSfs "https://launchpad.net/$release/trunk/+rdf" | \
      xq -r .'"rdf:RDF"."lp:ProductSeries"."lp:release"[0]."lp:ProductRelease"."lp:specifiedAt"."@rdf:resource"'
    )
    version=$(
      curl -LSfs "https://launchpad.net$resource" | \
      xq -r '."rdf:RDF"."lp:ProductRelease"."lp:version"'
    )

    curl -LSfs "https://launchpad.net/$release/trunk/$version/+download/$release-$version.tar.gz" | \
    sudo tar xz -C $src
  done
}

main
