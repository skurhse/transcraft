function make_key_pair {
  declare -Ag key_pair=(
    [bits]='4096'
    [email]="transcraft.${options[environment]}@transprogrammer.org"
    [file]="../${options[keyfile]}"
    [type]='rsa'
  )
}

function generate_key_pair {
  ssh_dir=$(dirname "${key_pair[file]}")

  ssh-keygen \
    -C "${key_pair[email]}" \
    -t "${key_pair[type]}"  \
    -b "${key_pair[bits]}"  \
    -f "${key_pair[file]}"  \
    -N ''
}