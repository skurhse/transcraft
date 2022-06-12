#!/usr/bin/env bash

# REQ: Provisions in cloud-init `runcmd`. <skr 2022-06-11>

# TODO: Check checksums. <skr 2022-06-11>

# !!!: Test workflow. <>

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
set -Cefuxo pipefail

arch=$(dpkg-arch)

etc=/etc
lib=/var/lib
local=usr/local bin=$local/bin src=$local/src

declare -A apt gh

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# DEBIAN_PACKAGE; https://packages.debian.org/search?keywords=ca-certificates
# DEBIAN_REPO:    https://salsa.debian.org/debian/ca-certificates.git

# UBUNTU_PACKAGE: https://packages.ubuntu.com/search?keywords=ca-certificates
# UBUNTU_REPO:    https://launchpad.net/ubuntu/+source/ca-certificates

apt[ca-certificates]='20211016~20.04.1'

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# DEBIAN_PACKAGE: https://packages.debian.org/search?keywords=fail2ban&searchon=names
# DEBIAN_REPO:    https://salsa.debian.org/python-team/packages/fail2ban

# GITHUB_REPO:    https://github.com/fail2ban/fail2ban

# OFFICIAL_SITE:  https://www.fail2ban.org/
# OFFICIAL_WIKI:  https://www.fail2ban.org/wiki/

# UBUNTU_PACKAGE: https://packages.ubuntu.com/search?keywords=fail2ban
# UBUNTU_REPO:    https://launchpad.net/ubuntu/+source/fail2ban

apt[fail2ban]='0.11.1-1'

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# DEBIAN_PACKAGE: https://packages.debian.org/bullseye/openjdk-17-jre-headless
# DEBIAN_REPO:    https://salsa.debian.org/openjdk-team/openjdk  

# OFFICIAL_SITE:  https://openjdk.java.net/
# OFFICIAL_WIKI:  https://wiki.openjdk.java.net

# UBUNTU_PACKAGE: https://packages.ubuntu.com/search?keywords=openjdk-17-jre-headless&searchon=names
# UBUNTU_REPO:    https://launchpad.net/ubuntu/+source/openjdk-17

apt[openjdk-17-jre-headless]='17.0.3+7-0ubuntu0.20.04.1'

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# UBUNTU_REPO: https://launchpad.net/ubuntu/+source/wget
# UBUNTU_PACKAGE: https://packages.ubuntu.com/search?keywords=wget&searchon=names

apt[wget]='1.20.3-1ubuntu2'

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# OFFICAL_DOCS:  https://prometheus.io/
# OFFICIAL_SITE: https://prometheus.io/docs/

# GITHUB_REPO:   https://github.com/prometheus/prometheus.git

gh[prometheus]='2.36.1'

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# GITHUB_REPO:    https://github.com/prometheus/node_exporter.git

# OFFICIAL_GUIDE: https://prometheus.io/docs/guides/node-exporter/
gh[node_exporter]='1.3.1'

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# GITHUB_REPO: https://github.com/dirien/minecraft-prometheus-exporter.git

gh[minecraft-exporter]='0.11.2'

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

download_github_release() {
  for key in ${!release[@]}
  do
    declare $key=${release[$key]}
  done
  
  local name="$name${1--}$version.linux-$arch"

  local url="https://github.com/$owner/$repo/releases/downloads/v$version/$name.tar.gz"

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

apt-get update

for $package in ${packages[@]}
do
  apt-get install $package=$version
done

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

name=prometheus version=${versions[$name]}

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

name=node_exporter version=${versions[$name]}]

declare -A release=([owner]=prometheus [repo]=$name [version]=$version)
declare -A unit=([owner]=$name [group]=$name [name]=$name)
declare -a programs=($name)

install_release
entities=(${programs[@]}) dir=$bin install_from_release
handle_systemctl

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

name=minecraft_exporter version=${versions[$name]}]

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
