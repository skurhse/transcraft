#!/usr/bin/env bash

# REQ: Configure sshd. <skr 2022-06>

set -o nounset
set -o xtrace

main() {
  sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
  service sshd restart

  systemctl restart fail2ban
}

main
