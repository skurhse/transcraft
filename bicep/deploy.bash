#!/usr/bin/env bash

# REQ: Deploys the bicep project. <skr 2022-06>

set +B -Cefuxo pipefail

cd "$(dirname "$(realpath "$0")")"

key=../.ssh/id_rsa

az deployment group create \
  --resource_group "$RESOURCE_GROUP" \
  --template-file 'main.bicep' \
  --parameters \
    user=${{ secrets.BICEP_USER }}
    servicePrincipal="$(cat $key)"
    publicKey="$(cat $key.pub)"
    privateKey="$(cat $key)"