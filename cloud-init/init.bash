#!/usr/bin/env bash

set -Cefuxo pipefail

# REQ: Provisions in cloud-init `runcmd`. <skr 2022-06-11>

# TODO: Check checksums. <skr 2022-06-11>

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

mkdir /tmp/cloud-init
cd $_

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

arch=$(arch)

etc=/etc
lib=/var/lib
local=/usr/local bin=$local/bin src=$local/src

declare -A versions=(
  [minecraft_exporter]=0.11.2
  [node_exporter]=1.3.1
  [quilt]=''
)

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

download_release() {
  for key in ${!release[@]}
  do
    declare $key=${release[$key]}
  done

  local name=$name-$version.linux-$arch 
  local url=https://github.com/$owner/$repo/releases/downloads/v$version/$name.tar.gz

  release[name]=$name
  release[url]=$url
  
  wget $url | tar x -C $src
}

install_from_release() {
  for entity in ${entities[@]}
  do
    cp -r ${release[name]}/$entity $dir
    chown -R ${unit[owner]}:${unit[group]} $dir/$entity
  done
}

install_dirs() {
  for dir in ${dirs[@]}
  do
    mkdir $dir
    chown ${unit[owner]}:${unit[group]} $dir
  done
}

handle_systemctl() {
  declare -n u=unit
  systemctl daemon-reload
  systemctl start $u
  systemctl enable $u
}

configure_iptables() {
  sudo iptables -A INPUT -p tcp -m state --state NEW --dport 25555 -j ACCEPT
  # where 25555 is the port
  # you do that for every ports
  # and then
  sudo iptables-save
  # and also
  sudo dpkg-reconfigure iptables-persistent

  # of course to block everything
  sudo iptables -P INPUT DROP
  sudo iptables -P OUTPUT DROP
  sudo iptables -P FORWARD DROP
}

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

name=prometheus
declare -A release=([owner]=$name [repo]=$name [version]=2.36.1)
declare -A dirs=([etc]=/etc/$name [lib]=/var/lib/$name)
declare -A unit=([owner]=$name [group]=$name [name]=$name)
declare -a programs=($name promtool)
declare -a configs=(consoles console_libraries name.yml)
declare -a exporters=(node minecraft)

install_release
install_dirs
entities=(${programs[@]}) dir=$bin install_from_release
entities=(${programs[@]}) dir=${dirs[etc]} install_from_release
handle_systemctl

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

for exporter in ${exporters[@]}
do
  install_exporter $exporter
done

cc=$c
c=node_exporter

declare -A ${c}_release=(
  [owner]=$cc
  [repo]=$c
)
set_github_release

declare -A ${c}_unit=(
  [owner]=$c
  [group]=$c
  [name]=$c
)

c=minecraft_exporter

declare -A ${c}_release=(
  [owner]=dirien
  [repo]=minecraft-$cc-exporter
)
set_github_release

declare -A ${c}_node_exporter_unit=(
  [owner]=node_exporter
  [group]=node_exporter
  [name]=node_exporter
)

declare -A node_exporter=(
  [git]=https://github.com/prometheus/node_exporter
  [release]=node_exporter-${versions[node_exporter]}.linux-$arch
  [owner]=node_exporter
  [group]=node_exporter
  [unit]=node_exporter
)
node_exporter[url]=${node_exporter[git]}/releases/download/v${versions[node_exporter]}/${node_exporter[release]}.tar.gz

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――


install_exporter() {
  declare -n p=$1_exporter

  install_to_source
  curl -LSfs {$e[url]} | tar x -C $src
  pushd $src
  
  program=
  cp ${e[release]} $bin 

  handle_systemctl ${e[unit]}
}




curl -sSL https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-$ARCH.tar.gz | tar -xz
cp node_exporter-$NODE_EXPORTER_VERSION.linux-$ARCH/node_exporter /usr/local/bin
chown node_exporter:node_exporter /usr/local/bin/node_exporter

curl -sSL https://github.com/dirien/minecraft-prometheus-exporter/releases/download/v$MINECRAFT_EXPORTER_VERSION/minecraft-exporter_$MINECRAFT_EXPORTER_VERSION.linux-$ARCH.tar.gz | tar -xz
cp minecraft-exporter /usr/local/bin
chown minecraft_exporter:minecraft_exporter /usr/local/bin/minecraft-exporter
systemctl start minecraft-exporter.service
systemctl enable minecraft-exporter.service

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

mkdir -p /minecraft
sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
service sshd restart
systemctl restart fail2ban
