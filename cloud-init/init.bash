#!/usr/bin/env bash

set -Cefuxo pipefail

# REQ: Provisions in cloud-init `runcmd`. <skr 2022-06-11>

# TODO: Check checksums. <skr 2022-06-11>

# !!!: Implement quilt. <>

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
  
  local name=$name${1--}$version.linux-$arch 

  local url=https://github.com/$owner/$repo/releases/downloads/v$version/$name.tar.gz

  release[name]=$name
  release[url]=$url
  
  wget $url | tar x -C $src
}

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

install_from_release() {
  for entity in ${entities[@]}
  do
    cp -r ${release[name]}/$entity $dir
    chown -R ${unit[owner]}:${unit[group]} $dir/$entity
  done
}

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

install_dirs() {
  for dir in ${dirs[@]}
  do
    mkdir $dir
    chown ${unit[owner]}:${unit[group]} $dir
  done
}

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

handle_systemctl() {
  declare -n u=unit
  systemctl daemon-reload
  systemctl start $u
  systemctl enable $u
}

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

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
version=2.36.1

declare -A release=([owner]=$name [repo]=$name [version]=$version)
declare -A dirs=([etc]=/etc/$name [lib]=/var/lib/$name)
declare -A unit=([owner]=$name [group]=$name [name]=$name)
declare -a programs=($name promtool)
declare -a configs=(consoles console_libraries name.yml)
declare -a exporters=(node minecraft)

install_release
install_dirs
entities=(${programs[@]}) dir=$bin install_from_release
entities=(${configs[@]}) dir=${dirs[etc]} install_from_release
handle_systemctl

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

name=node_exporter
version=1.3.1

declare -A release=([owner]=prometheus [repo]=$name [version]=$version)
declare -A unit=([owner]=$name [group]=$name [name]=$name)
declare -a programs=($name)

install_release
entities=(${programs[@]}) dir=$bin install_from_release
handle_systemctl

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

name=minecraft-exporter
version=0.13.0

declare -A release=([owner]=dirien [repo]=minecraft-prometheus-exporter [version]=$version)
declare -A unit=([owner]=$name [group]=$name [name]=$name)
declare -a programs=($name)

install_release _
entities=(${programs[@]}) dir=$bin install_from_release
handle_systemctl

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

mkdir -p /minecraft
sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
service sshd restart
systemctl restart fail2ban
URL="https://papermc.io/api/v2/projects/paper/versions/1.18.1/builds/136/downloads/paper-1.18.1-136.jar"
curl -sLSf $URL > /minecraft/server.jar
echo "eula=true" > /minecraft/eula.txt
mv /tmp/server.properties /minecraft/server.properties
chmod a+rwx /minecraft
systemctl restart minecraft.service
systemctl enable minecraft.service
