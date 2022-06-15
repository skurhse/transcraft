#!/usr/bin/env bash

# REQ: Creates the deploy pipeline. <skr 2022-06-14*>

[ $(bash --version | head -1 | cut -d ' ' -f4) == '5.1.16(1)-release' ] && \
[ $(az version --query '"azure-cli"' -o tsv)   == '2.37.0'            ] && \
[ $(gh version | head -1 | cut -d ' ' -f3)     == '2.12.1'            ] || \
exit

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
  key[file]=".ssh/id_${key[type]}"
}

make_group() {
  declare -Ag group=(
    [name]='transcraft'
    [location]='centralus'
  )
}

make_principal() {
  declare -Ag principal=(
    [name]='github_actions'
    [role]='contributor'
    [scope]="/subscriptions/$1/resourceGroups/$2"
  )
}

main() {
  fetch_subscription_id
  fetch_user_id

  make_group
  if group_exists; then delete_group; fi
  create_group

  make_principal "$subcription_id" "${group[name]}"
  if principal_exists; then delete_principal; fi
  create_group

  make_key
  generate_key

  # TODO: loop
  gh secret set SSH_PRIVATE_KEY < ${key[file]}
  gh secret set SSH_PUBLIC_KEY < ${key[file]}.pub

  gh secret set AZURE_CREDENTIALS -b "$credentials"
  gh secret set AZURE_RESOURCE_GROUP -b "${group[name]}"
  gh secret set AZURE_SUBSCRIPTION -b "$subcription_id"

  gh secret set BICEP_SERVICE_PRINCIPAL -b "${principal[id]}"
  gh secret set BICEP_USER -b "$user_id"
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

create_group() {
  az group create --name "${group[name]}" --location "${group[location]}"
}
delete_group() {
  az group delete --name "${group[name]}"
}
group_exists() {
  [[ $(az group exists -n ${group[name]}) == true ]] && return 0 || return 1
}

create_principal() {
  credentials=$(
    az ad sp create-for-rbac \
    --name   ${principal[name]} \
    --role   ${principal[role]} \
    --scopes ${principal[scope]} \
    --sdk-auth
  )
  declare -g credentials
  principal[client_id]=$(jq -r .clientId <<< $credentials)
  principal[id]=$(az ad sp show --id ${principal[client_id]} --query objectId -o tsv)
}
delete_principal() {
    az ad sp delete --id $old_principal_id
}
principal_exists() {
  principals=$(az ad sp list --display-name ${principal[name]})

  size=$(jq length <<< $listed_principals)
  case $size in
  0)
    old_principal_id=$(jq -r .[0].objectId <<< $principals)
    declare -g old_principal_id
    return 0
    ;;
  1)
    return 1
    ;;
  *)
    echo "error: unexpected principals size $size."
    exit 1
    ;;
  esac
}

fetch_subscription_id() {
  subcription_id=$(az account show --query id -o tsv)
  declare -g subcription_id
}

fetch_user_id() {
  user_id=$(az ad user list --query [].objectId --output tsv --only-show-errors)
  declare -g user_id
}

main
