export RESOURCE_GROUP = transcraft

OUT_DIR = out
SSH_DIR = $(OUT_DIR)/ssh

export SSH_PRIVATE_KEY = $(SSH_DIR)/id_rsa
SSH_PUBLIC_KEY = $(SSH_PRIVATE_KEY).pub

MIME_FILE = $(OUT_DIR)/cloud-init.mime

.PHONY: user-data
user-data: $(MIME_FILE)

.PHONY: ssh-keys
ssh-keys: $(SSH_PUBLIC_KEY) $(SSH_PRIVATE_KEY)

$(SSH_PRIVATE_KEY) $(SSH_PUBLIC_KEY) &:
	make/ssh-keys.bash

$(SSH_DIR): $(OUT_DIR)
	mkdir $(SSH_DIR)

$(MIME_FILE): $(OUT_DIR)
	cloud-init devel make-mime \
	  -a cloud-init/cloud-config/config.yaml:cloud-config \
	  -a cloud-init/x-shellscript/per-boot.bash:x-shellscript-per-boot \
	  -a cloud-init/x-shellscript/per-instance.bash:x-shellscript-per-instance \
	  -a cloud-init/x-shellscript/per-once.bash:x-shellscript-per-once \
	> $(OUT_DIR)/cloud-init.mime

$(OUT_DIR):
	mkdir $(OUT_DIR)

.PHONY: deployment
deployment: $(MIME_FILE)
	bicep/deploy.bash
