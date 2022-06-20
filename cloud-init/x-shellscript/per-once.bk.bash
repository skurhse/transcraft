#!/usr/bin/env bash

# REQ: Run-once script. <skr 2022-06>

set -o nounset
set -o xtrace

architecture="$(dpkg --print-architecture)"

etc='/etc' lib='/var/lib'
local='/usr/local' bin="$local/bin" src="$local/src"

main() {
  install_prometheus
  install_quilt

  handle_sshd
}

install_prometheus() {
  local name='prometheus' version='2.36.1'

  local -A release=(
    [delimiter]='-'
    [name]="$name"
    [owner]="$name"
    [repository]="$name"
    [version]="$version"
  )
  release[archive]=$(download_github_release)

  local -A unit=(
    [group]="$name"
    [name]="$name"
    [user]="$name"
  )
  local -A dirs=(
    [etc]='/etc/prometheus'
    [lib]='/var/lib/prometheus'
  )
  make_dirs

  local nodes=(
    'prometheus'
    'promtool'
  )
  local dir="$bin"
  install_release_nodes

  local nodes=(
    'consoles'
    'console_libraries'
    'prometheus.yml'
  )
  local dir="${dirs[etc]}"
  install_release_nodes

  handle_unit

  install_node_exporter
  install_minecraft_exporter
}

install_node_exporter() {
  local name='node_exporter' version='1.3.1'

  local -A release=(
    [delimiter]='-'
    [name]="$name"
    [owner]='prometheus'
    [repository]="$name"
    [version]="$version"
  )
  release[archive]=$(download_github_release)

  local -A unit=(
    [group]="$name"
    [name]="$name"
    [user]="$name"
  )

  local -a nodes=(
    "$name"
  )
  local dir="$bin"
  install_release_nodes

  handle_unit
}

install_minecraft_exporter() {
  name='minecraft-exporter' version='0.13.0'

  local -A release=(
    [delimiter]='_'
    [name]="$name"
    [owner]='dirien'
    [repository]='minecraft-prometheus-exporter'
    [version]="$version"
  )
  release[archive]=$(mkdir=yes download_github_release)

  local -A unit=(
    [user]="$name"
    [group]="$name"
    [name]="$name"
  )

  local -a nodes=(
    "$name"
  )
  dir=$bin
  install_release_nodes

  handle_unit
}

install_quilt() {
  install_quilt_installer
}

install_quilt_installer() {
   local name='quilt-installer' version='latest'

  declare -A release=(
    [delimiter]='-'
    [name]="$name"
    [owner]='quiltmc'
    [repository]="$name"
    [version]="$version"
  )
  release[archive]=$(download_quilt_release)

  declare -A unit=(
    [user]='quilt'
    [group]='quilt'
  )
  local -a dirs=(
    '/quilt'
  )
  make_dirs

  handle_unit
}

download_github_release() {
  . <(release_source)

  local archive="$name$delimiter$version.linux-$architecture"

  local url="https://github.com"

  local segments=(
    "$owner"
    "$repository"
    "releases"
    "download"
    "v$version"
    "$archive.tar.gz"
  )

  make_url

  if [[ ${mkdir-no} == 'yes' ]]; then
    local old_src="$src"
    local src
    src="$old_src/$archive"

    mkdir -p "$archive"
  fi

  curl -LSfs "$url" | tar xz -C "$src"

  printf "$archive"
}

download_quilt_release() {
  . <(release_source)

  local url="https://maven.quiltmc.org"

  local archive="quilt-install-$version"

  local segments=(
    "repository"
    "release"
    "org"
    "quiltmc"
    "$name"
    "latest"
    "$archive.jar"
  )

  make_url

  curl -LSfs "$url" > "$src/"
}

release_source() {
  echo 'for attr in "${!release[@]}"; do
    local "$attr"="${release[$attr]}"
  done'
}

install_release_nodes() {
  for node in "${nodes[@]}"; do
    cp -r "$src/${release[name]}/$node" "$dir"
    chown -R "${unit[user]}:${unit[group]}" "$dir/$node"
  done
}

make_url() {
  for segment in "${segments[@]}"; do
    url+="/$segment"
  done
}

make_dirs() {
  for dir in "${dirs[@]}"; do
    mkdir -p "$dir"
    chown "${unit[user]}:${unit[group]}" "$dir"
  done
}

handle_unit() {
  local name=${unit[name]}

  systemctl daemon-reload
  systemctl start "$name"
  systemctl enable "$name"
}

handle_iptables() {
  iptables -I INPUT -j ACCEPT

  # iptables -A INPUT -p tcp -m state --state NEW --dport 25555 -j ACCEPT
  # iptables-save
  # dpkg-reconfigure iptables-persistent

  # iptables -P INPUT DROP
  # iptables -P OUTPUT DROP
  # iptables -P FORWARD DROP
}

handle_sshd() {
  sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
  service sshd restart

  systemctl restart fail2ban
}

main
