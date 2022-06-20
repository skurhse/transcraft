#!/usr/bin/env bash

# REQ: Installs the quilt service. <skr 2022-06>

set -o nounset
set -o xtrace

lib='/usr/local/lib/quilt'

name='quilt' version='1.19'

main() {
  installer=$(download_installer)
  run_installer
  handle_service
}

download_installer() {
  local name='quilt-installer'
  local version='latest'
  local url="https://maven.quiltmc.org"
  local installer="quilt-installer-$version.jar"

  mkdir -p "$lib"

  local segments=(
    "repository"
    "release"
    "org"
    "quiltmc"
    "$name"
    "$version"
    "$installer"
  )

  for segment in "${segments[@]}"; do
    url+="/$segment"
  done

  curl -LSfs "$url" > "$lib/$installer"

  echo "$installer"
}

run_installer() {
  java -jar "$lib/$installer" install server "$version" \
    --download-server \
    --install-dir="$lib/server"

  chown -R "$name:$name" "$lib/server"
}

handle_service() {
  systemctl daemon-reload
  systemctl start "$name"
  systemctl enable "$name"
}

main
