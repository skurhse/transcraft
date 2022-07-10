function make_key_pair {
  declare -Ag key_pair=(
    [type]='rsa'
    [bits]='4096'
    [email]='transcraft@transprogrammer.org'
  )
  key_pair[file]="$SSH_PRIVATE_KEY"
}

generate_key() {
  ssh_dir=$(dirname "${key[file]}")

  ssh-keygen \
    -C "${key[email]}" \
    -t "${key[type]}"  \
    -b "${key[bits]}"  \
    -f "${key[file]}"  \
    -N ''
}