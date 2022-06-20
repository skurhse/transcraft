#!/usr/bin/env bash

# REQ: Creates a cloud-init user-data MIME multi-part archive. <skr 2022-06>

set -Cefuxo pipefail

main() {
    rm -f "$MIME_FILE"

 	cloud-init devel make-mime \
	  -a cloud-init/cloud-config/config.yaml:cloud-config \
	  -a cloud-init/x-shellscript/per-instance/install_quilt.bash:x-shellscript-per-instance \
	  -a cloud-init/x-shellscript/per-instance/configure_iptables.bash:x-shellscript-per-instance \
	  -a cloud-init/x-shellscript/per-instance/configure_sshd.bash:x-shellscript-per-instance \
	> "$MIME_FILE"
}

main
