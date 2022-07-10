#!/usr/bin/env bash

set -o errexit
set -o noclobber
set -o noglob
set -o nounset
set -o pipefail
set -o xtrace

make_key() {
  declare -Ag key=(
    [type]='rsa'
    [bits]='4096'
    [email]='transcraft@transprogrammer.org'
  )
  key[file]="$SSH_PRIVATE_KEY"
}

main() {
  make_key
  generate_key
}

generate_key() {
  realpath=$(realpath "$0")
  dirname=$(dirname "$realpath")
  cd "$dirname/.."

  ssh_dir=$(dirname "${key[file]}")
  mkdir -p "$ssh_dir"
  ssh-keygen \
    -C "${key[email]}" \
    -t "${key[type]}"  \
    -b "${key[bits]}"  \
    -f "${key[file]}"  \
    -N ''
}

main
