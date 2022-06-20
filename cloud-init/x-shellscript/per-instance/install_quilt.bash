#!/usr/bin/env bash

# REQ: Installs the quilt service. <skr 2022-06>

set -o nounset
set -o xtrace

lib='/usr/local/lib/quilt'

name='quilt-installer'
version='latest'

url="https://maven.quiltmc.org"

archive="quilt-installer-$version.jar"

minecraft_version='1.19'

main() {
  download_installer
  run_installer
  handle_unit
}

download_installer() {

  mkdir -p "$lib"

  local segments=(
    "repository"
    "release"
    "org"
    "quiltmc"
    "$name"
    "$version"
    "$archive"
  )

  for segment in "${segments[@]}"; do
    url+="/$segment"
  done

  curl -LSfs "$url" > "$lib/$archive"
}

run_installer() {
  java -jar "$lib/$archive" install server "$minecraft_version" --download-server
}

main

# chown -R "${unit[user]}:${unit[group]}" "$dir/$node"

# handle_unit() {
#   local name=${unit[name]}
#   local -A unit=(
#     [name]='quilt'
#     [user]='quilt'
#     [group]='quilt'
#   )

#   systemctl daemon-reload
#   systemctl start "$name"
#   systemctl enable "$name"
# }

