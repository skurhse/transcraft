# REQ: Parses make script options. <skr 2022-07>

function parse_options {
  local longopts='bastion:,location:,resource-group:,virtual-machine:'
  local opts='b:,l:,g:,m:'
  local parsed
  declare -Ag options

  parsed=$(getopt --options="$opts" --longoptions="$longopts" --name "$0" -- "$@")
  eval set -- "$parsed"

  for ((i = 1; i <= $#; i++)); do
    (( j = i + 1 ))
    case "${!i}" in
        -b|--bastion)
          options[bastion]="${!j}"
          (( i++ ))
          ;;
        -g|--resource-group)
          options[resource_group]="${!j}"
          (( i++ ))
          ;;
        -l|--location)
          options[location]="${!j}"
          (( i++ ))
          ;;
        -m|--virtual-machine)
          options[virtual_machine]="${!j}"
          (( i++ ))
          ;;
        --)
          if [[ $i -lt $# ]]; then
            (( k = i - $# - 1))
            echo "Invalid arguments: ${@:k}"
            exit 1
          fi
          break
          ;;
        *)
          echo "Invalid option: ${!i}"
          exit 3
          ;;
    esac
  done

}
