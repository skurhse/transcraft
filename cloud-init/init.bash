#!/usr/bin/env bash

# REQ: Provisions in cloud-init `runcmd`. <skr 2022-06-11>

set -Cefuxo pipefail

arch=$(arch)

bin=/usr/local/bin
src=/usr/local/src

declare -A versions=(
  [minecraft_exporter]=0.11.2
  [node_exporter]=1.3.1
  [paper]=''
  [prometheus]=2.36.1
)

declare -A prometheus=(
  [git]=https://github.com/prometheus/prometheus
  [release]=prometheus-${versions[prometheus]}.linux-$arch
  [checksum]=e5e555c84f04ccf20821fe907088e7ccecf418c88be3bd552b07c774d448d339
  [etc]=/etc/prometheus
  [lib]=/var/lib/prometheus
  [owner]=prometheus
  [group]=prometheus
  [unit]=prometheus
)
prometheus[url]=${prometheus[git]}/releases/download/v${versions[prometheus]}/${prometheus[release]}.tar.gz

prometheus_programs=(prometheus promtool)
prometheus_configs=(consoles/ console_libraries/ prometheus.yml)

declare -A node_exporter=(
  [git]=https://github.com/prometheus/node_exporter
  [release]=node_exporter-${versions[node_exporter]}.linux-$arch
  [owner]=node_exporter
  [group]=node_exporter
  [unit]=node_exporter
)
node_exporter[url]=${node_exporter[git]}/releases/download/v${versions[node_exporter]}/${node_exporter[release]}.tar.gz

exporters=(node minecraft)

main() {
  cd /tmp
  mkdir cloud-init
  cd $_

  configure_iptables
  
  install_prometheus
  
  for exporter in ${exporters[@]}
  do
    install_exporter $exporter
  done

 install_paper
}

configure_iptables() {
  iptables -I INPUT -j ACCEPT
}

install_prometheus() {
  declare -n service=prometheus
  declare -n programs=prometheus_programs
  declare -n configs=prometheus_configs

  mkdir ${service[etc]} mkdir ${service[lib]}

  install_to_source

  pushd $src
  for $entity in ${programs[@]} ${configs[@]} ${p[lib]}; do
    install_to_bin
  done
  popd

  handle_systemctl
}

install_exporter() {
  declare -n p=$1_exporter

  install_to_source
  curl -LSfs {$e[url]} | tar x -C $src
  pushd $src
  
  program=
  cp ${e[release]} $bin 

  handle_systemctl ${e[unit]}
}

install_to_source() {
  wget ${p[url]} | tar x -C $src
}

install_to_bin() {
    declare e=$entity

    cp -r ${p[release]}/$e $bin
    chown -R ${p[owner]}:${p[group]} $bin/$element

    cp -r ${p[release]}/$e ${p[etc]} 
    chown -R ${p[owner]}:${p[group]} ${p[etc]}/$e
}


handle_systemctl() {
  systemctl daemon-reload
  systemctl start $1
  systemctl enable $1
}

curl -sSL https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-$ARCH.tar.gz | tar -xz
cp node_exporter-$NODE_EXPORTER_VERSION.linux-$ARCH/node_exporter /usr/local/bin
chown node_exporter:node_exporter /usr/local/bin/node_exporter

curl -sSL https://github.com/dirien/minecraft-prometheus-exporter/releases/download/v$MINECRAFT_EXPORTER_VERSION/minecraft-exporter_$MINECRAFT_EXPORTER_VERSION.linux-$ARCH.tar.gz | tar -xz
cp minecraft-exporter /usr/local/bin
chown minecraft_exporter:minecraft_exporter /usr/local/bin/minecraft-exporter
systemctl start minecraft-exporter.service
systemctl enable minecraft-exporter.service

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
}

main "$@"
