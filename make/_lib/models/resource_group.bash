# REQ: Resource group library functions. <skr 2022-07>

function make_resource_group {
  declare -Ag resource_group=(
    [location]="${options[location]}"
        [name]="${options[resource_group]}"
  )
}

function create_resource_group {
  az group create \
    --name "${resource_group[name]}" \
    --location "${resource_group[location]}"
}
