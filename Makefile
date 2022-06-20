export RESOURCE_GROUP = transcraft
export LOCATION = centralus

export SERVICE_PRINCIPAL = github_actions

OUT_DIR = out
SSH_DIR = $(OUT_DIR)/ssh

export SSH_PRIVATE_KEY = $(SSH_DIR)/id_rsa
export SSH_PUBLIC_KEY = $(SSH_PRIVATE_KEY).pub

export MIME_FILE = $(OUT_DIR)/cloud-init.mime

.PHONY: user-data
user-data: $(MIME_FILE)

.PHONY: ssh-keys
ssh-keys: $(SSH_PUBLIC_KEY) $(SSH_PRIVATE_KEY)

$(SSH_PRIVATE_KEY) $(SSH_PUBLIC_KEY) &:
	make/ssh-keys.bash

$(SSH_DIR): $(OUT_DIR)
	mkdir $(SSH_DIR)

$(MIME_FILE): $(OUT_DIR)
	make/mime-file.bash

$(OUT_DIR):
	mkdir $(OUT_DIR)

.PHONY: deployment
deployment: $(MIME_FILE)
	make/deployment.bash
