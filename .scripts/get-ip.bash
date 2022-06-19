#!/usr/bin/env bash

# REQ: Gets the virtual machine public ip address. <skr 2022-06>

query='properties.outputs.minecraftPublicIP.value'
g='transcraft'
n='main'
o='tsv'

az deployment group show -g $g -n $n --query $query -o $o 
