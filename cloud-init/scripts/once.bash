#!/usr/bin/env bash

# REQ: Run-once script. <skr 2022-06>

set -Cefuxo pipefail

architecture=$(dpkg --print-architecture)

etc=/etc
lib=/var/lib
local=/usr/local
bin=$local/bin
src=$local/src

set_archive() {
local name=$1 version=$2 owner=$3 repo=$4 delim=${5--}

archive=$name$delim$version.linux-$architecture

local url=https://github.com/$owner/$repo/releases/download/v$version/$archive.tar.gz

if [ $mkdir = yes ]; then
local src=$src/$archive
mkdir -p $archive
fi

curl -LSfs $url | tar xz -C $src
}

make_dirs() {
local user=$1 group=$2

for dir in ${dirs[@]}; do
mkdir $dir
chown $user:$group $dir
done
}

download_quilt_release() {
url=https://maven.quiltmc.org/repository/release/org/quiltmc/$name/latest/quilt-installer-latest.jar

curl -sLSf $url > /quilt/server.jar
echo "eula=true" > /minecraft/eula.txt
mv /tmp/server.properties /minecraft/server.properties
chmod a+rwx /minecraft

}

install_nodes() {
for node in ${nodes[@]}
do
cp -r $src/${release[name]}/$node $dir
chown -R ${unit[owner]}:${unit[group]} $dir/$node
done
}


handle_unit() {
systemctl daemon-reload
systemctl start $1
systemctl enable $1
}

configure_iptables() {
iptables -I INPUT -j ACCEPT

# iptables -A INPUT -p tcp -m state --state NEW --dport 25555 -j ACCEPT
# iptables-save
# dpkg-reconfigure iptables-persistent

# iptables -P INPUT DROP
# iptables -P OUTPUT DROP
# iptables -P FORWARD DROP
}

declare -A unit=(
[user]=$name
[group]=$name
[name]=$name
)

archive=
set_archive prometheus 2.36.1 prometheus prometheus

declare -A dirs=(
[etc]=/etc/prometheus
[lib]=/var/lib/prometheus
)
make_dirs

nodes=(
prometheus
promtool
)
dir=$bin
install_from_source

nodes=(
consoles
console_libraries
prometheus.yml
)
dir=${dirs[etc]}
install_from_source

handle_unit

declare -A release=(
[owner]=prometheus
[repo]=node_exporter
[version]=1.3.1
)
download_release

declare -A unit=(
[owner]=$name
[group]=$name
[name]=$name
)
declare -a programs=($name)

download_github_release
nodes=${programs[@]} dir=$bin install_from_source
name=${unit[name]} handle_unit


version=${versions[$name]}

declare -A release=([owner]=dirien [repo]=minecraft-prometheus-exporter [version]=$version)
declare -A unit=([owner]=$name [group]=$name [name]=$name)
declare -a programs=($name)

mkdir=yes delim=_ download_github_release
nodes=${programs[@]} dir=$bin install_from_source
name=${unit[name]} handle_unit


name=quilt-installer version=${versions[$name]} 

declare -A release=(
[name]=quilt-installer
[owner]=quiltmc
[repo]=quilt-installer
[version]=latest
)
declare -A unit=([owner]=quiltmc [name]=$name)
delcare dirs=(/quilt)

make_dirs
download_quilt_release
handle_unit


sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
service sshd restart


systemctl restart fail2ban