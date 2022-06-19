#!/usr/bin/env bash

# REQ: Tests cloud-init with multipass. <skr 2022-06 s:inprogress>

# SEE: https://maas.io/tutorials/build-a-maas-and-lxd-environment-in-30-minutes-with-multipass-on-ubuntu <>

set -o xtrace

name='transcraft' cpus='1' mem='8GB' disk='32GB'

init="$(dirname "$(realpath "$0")")/../out/cloud-init.mime"

multipass launch --name "$name" -c$cpus -m$mem -d$disk --cloud-init "$init"

multipass exec transcraft -- cat /var/log/cloud-init-output.log

multipass delete --purge "$name"
