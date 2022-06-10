#!/usr/bin/env bash

# REQ: Imports the bicep project. <skr 2022-06-09>

# SEE: https://github.com/dirien/infrastructure-as-code-workshop/tree/main/bicep-azure-minecraft <>

owner='dirien'
repo='infrastructure-as-code-workshop'
ref='main'

path='dirien-infrastructure-as-code-workshop-292d52e/bicep-azure-minecraft'

rp=$(realpath "$0"); dn=$(dirname "$rp")..; cd "$dn"

rm -rf bicep; mkdir $_; pushd $_
gh api "/repos/$owner/$repo/tarball/$ref" | tar xv --strip-components 2 "$path"
popd
