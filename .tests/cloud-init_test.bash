#!/usr/bin/env bash

# REQ: Tests cloud-init with maas. <skr 2022-06-12>

# SEE: https://maas.io/tutorials/build-a-maas-and-lxd-environment-in-30-minutes-with-multipass-on-ubuntu <>

set -Cefuxo pipefail

path=$(realpath "$0"); init="$(dirname $path)/../cloud-init/init.yaml"

name='transcraft' cpus='1' mem='4GB' disk='32GB'

if multipass launch --name "$name" -c$cpus -m$mem -d$disk --cloud-init "$init"
then
  multipass delete --purge foo
fi
