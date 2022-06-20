#!/usr/bin/env bash

# REQ: Configure iptables. <skr 2022-06>

set -o nounset
set -o xtrace

main() {
  iptables -I INPUT -j ACCEPT

  # iptables -A INPUT -p tcp -m state --state NEW --dport 25555 -j ACCEPT
  # iptables-save
  # dpkg-reconfigure iptables-persistent

  # iptables -P INPUT DROP
  # iptables -P OUTPUT DROP
  # iptables -P FORWARD DROP
}

main
