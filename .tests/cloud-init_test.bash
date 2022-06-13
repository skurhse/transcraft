#!/usr/bin/env bash

# REQ: Tests cloud-init with maas. <skr 2022-06-12>

# SEE: https://maas.io/tutorials/build-a-maas-and-lxd-environment-in-30-minutes-with-multipass-on-ubuntu <>

set -Cefuxo pipefail

path=$(realpath "$0"); init="$(dirname $path)/../cloud-init/init.bash"

cpus='1' mem='4GB' disk='32GB'

name='transcraft'
exec=('lsb_release' '-a')

multipass launch --name "$name" -c$cpus -m$mem -d$disk --cloud-init "$init"
multipass delete --purge foo

multipass exec "$name" -- "${exec[@]}"
