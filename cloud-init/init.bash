#!/usr/bin/env bash

# REQ: Provisions in cloud-init `runcmd`. <skr 2022-06-11>

set -Cefuxo pipefail

arch=$(arch)


export ARCH=amd64
export NODE_EXPORTER_VERSION=1.3.1
export MINECRAFT_EXPORTER_VERSION=0.11.2
export PROM_VERSION=2.33.0

git
iptables -I INPUT -j ACCEPT



mkdir /etc/prometheus
mkdir /var/lib/prometheus

curl -sSL https://github.com/prometheus/prometheus/releases/download/v$PROM_VERSION/prometheus-$PROM_VERSION.linux-$ARCH.tar.gz | tar -xz
cp prometheus-$PROM_VERSION.linux-$ARCH/prometheus /usr/local/bin/
cp prometheus-$PROM_VERSION.linux-$ARCH/promtool /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool
cp -r prometheus-$PROM_VERSION.linux-$ARCH/consoles /etc/prometheus
cp -r prometheus-$PROM_VERSION.linux-$ARCH/console_libraries /etc/prometheus
chown -R prometheus:prometheus /var/lib/prometheus
chown -R prometheus:prometheus /etc/prometheus/consoles
chown -R prometheus:prometheus /etc/prometheus/console_libraries
mv /tmp/prometheus.yml /etc/prometheus/prometheus.yml
chown prometheus:prometheus /etc/prometheus/prometheus.yml
systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus

curl -sSL https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-$ARCH.tar.gz | tar -xz
cp node_exporter-$NODE_EXPORTER_VERSION.linux-$ARCH/node_exporter /usr/local/bin
chown node_exporter:node_exporter /usr/local/bin/node_exporter
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter
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