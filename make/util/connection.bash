# REQ: Creates an ssh connection via bastion. <skr 2022-07>

if [[ $LVL == 'debug' ]]
then
  set -o xtrace
fi

source lib/shell.bash
source lib/options.bash
source lib/models/resource_group.bash
source lib/models/bastion.bash
source lib/models/virtual_machine.bash

function main {
  parse_options "$@"

  make_resource_group
  make_bastion
  make_virtual_machine

  virtual_machine[id]="$(get_virtual_machine_id)"
  connect_to_bastion
}

main "$@"
