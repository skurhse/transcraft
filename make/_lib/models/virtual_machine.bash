function make_virtual_machine {
  declare -Ag virtual_machine=(
      [id]=
    [name]="${options[virtual_machine]}"
  )
}

function get_virtual_machine_id {
  az vm show \
    --name           "${virtual_machine[name]}" \
    --output         'tsv'                      \
    --query          'id'                       \
    --resource-group "${resource_group[name]}"
}
