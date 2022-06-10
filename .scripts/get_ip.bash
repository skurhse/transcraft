#!/usr/bin/env bash

set -Cefuxo pipefail

az deployment group show -n main --query properties.outputs.minecraftPublicIP.value -o tsv
