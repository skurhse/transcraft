#!/usr/bin/env bash

# REQ: Tests cloud-init with maas. <skr 2022-06-12>

# SEE: https://maas.io/tutorials/build-a-maas-and-lxd-environment-in-30-minutes-with-multipass-on-ubuntu <>

set -Cefuxo pipefail

path=$(realpath "$0"); init="$(dirname $path)/../cloud-init/cloud-config.yaml"

name='transcraft' cpus='1' mem='4GB' disk='32GB'

! multipass delete --purge "$name"
multipass launch --name "$name" -c$cpus -m$mem -d$disk --cloud-init "$init"
multipass exec transcraft -- cat /var/log/cloud-init-output.log
