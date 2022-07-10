#!/usr/bin/env bash

# REQ: Creates the environment resource group. <>

set +o braceexpand
set -o errexit
set -o noclobber
set -o nounset
set -o noglob
set -o pipefail

if [[ $LVL == 'debug' ]]
then
  set -o xtrace
fi

realpath="$(realpath "$0")"
dirname="$(dirname "$realpath")"
cd "$dirname/.."

source lib/options.bash

function main {
  parse_options "$@"

  make_resource_group
  create_resource_group
}
