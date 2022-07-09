#!/usr/bin/env bash

# REQ: Bastion library functions. <skr 2022-07>

function make_bastion {
  declare -Ag bastion=(
    [auth-type]='AAD'
    [name]="${options[bastion]}"
    [username]='minecraft'
  )
}

function connect_to_bastion {
  az network bastion ssh \
    --auth-type          "${bastion[auth-type]}"    \
    --name               "${bastion[name]}"         \
    --resource-group     "${resource_group[name]}"  \
    --target-resource-id "${virtual_machine[id]}"   \
    --debug
}
