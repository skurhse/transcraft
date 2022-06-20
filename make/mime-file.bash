#!/usr/bin/env bash

# REQ: Creates a cloud-init user-data MIME multi-part archive. <skr 2022-06>

set -Cefuxo pipefail

main() {
    rm -f "$MIME_FILE"

 	cloud-init devel make-mime \
	  -a cloud-init/cloud-config/config.yaml:cloud-config \
	  -a cloud-init/x-shellscript/per-boot.bash:x-shellscript-per-boot \
	  -a cloud-init/x-shellscript/per-instance.bash:x-shellscript-per-instance \
	  -a cloud-init/x-shellscript/per-once.bash:x-shellscript-per-once \
	> "$MIME_FILE"
}

main
