#!/usr/bin/env bash

# REQ: Sets up the deploy action. <skr 2022-06-11>

set -Cefuxo pipefail

sub_id=$(az account show --query id -o tsv)

declare -A key=(
  [type]=rsa
  [bits]=4096
  [email]=hello@drruruu.dev
)
key[file]=.ssh/id_${key[type]}

declare -A group=(
  [name]=transcraft
  [location]=centralus
)

declare -A sp=(
  [name]=github_actions
  [role]=contributor
  [scope]=/subscriptions/$sub_id/resourceGroups/${group[name]}
)

declare -A user
user[id]=$(az ad user list --query [].objectId --output tsv --only-show-errors)

if [ $(az group exists -n ${group[name]}) = true ]
then
  az group delete -n "${group[name]}"
fi
az group create -n "${group[name]}" -l "${group[location]}"

old_sps=$(az ad sp list --display-name ${sp[name]})
old_sps_length=$(jq length <<< $old_sps)
case $old_sps_length in
0)
  ;;
1)
  old_sp_id=$(jq -r .[0].objectId <<< $old_sps)
  az ad sp delete --id $old_sp_id
  ;;
*)
  exit
  ;;
esac
credentials=$(az ad sp create-for-rbac -n ${sp[name]} --role ${sp[role]} --scopes ${sp[scope]} --sdk-auth)
sp[client_id]=$(jq -r .clientId <<< $credentials)
sp[id]=$(az ad sp show --id ${sp[client_id]} --query objectId -o tsv)

realpath=$(realpath $0); dirname=$(dirname $realpath); cd $dirname/..

ssh_dir=$(dirname ${key[file]})
mkdir -p $ssh_dir
ssh-keygen -C ${key[email]} -t ${key[type]} -b ${key[bits]} -f ${key[file]} -N ''

gh secret set SSH_PRIVATE_KEY < ${key[file]}
gh secret set SSH_PUBLIC_KEY < ${key[file]}.pub

gh secret set AZURE_CREDENTIALS -b "$credentials"
gh secret set AZURE_RESOURCE_GROUP -b ${group[name]}
gh secret set AZURE_SUBSCRIPTION -b $sub_id

gh secret set BICEP_SERVICE_PRINCIPAL -b ${sp[id]}
gh secret set BICEP_USER -b ${user[id]}
