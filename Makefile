# NOTE: To see a list of typical targets execute `make help` <skr 2022-07>

.PHONY: help
help:
	@echo 'Cleaning targets:'
	@echo ' clean   - Remove most generated files but keep the config.'
	@echo ' reset   - Remove all generated files.'
	@echo ''
	@echo 'Build targets:'
	@echo '  all    - Build all targets.'
	@echo ''
	@echo 'Miscellaneous targets:'
	@echo '  help   - Display this usage text.'
	@echo ''

RESOURCE_GROUP = transcraft
LOCATION = centralus
BASTION = bastion-d4vxd4ztxl3dk-bh
VIRTUAL_MACHINE = transcraft-d4vxd4ztxl3dk-vm

SHELL = /usr/bin/env bash
DEBUG ?= no

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

$(MIME_FILE): $(OUT_DIR) cloud-init/*/*
	make/mime-file.bash

$(OUT_DIR):
	mkdir $(OUT_DIR)

.PHONY: deployment
deployment: $(MIME_FILE)
	cd make && ./deployment.bash

.PHONY: connection
connection:
	$(call handle_debug) \
	cd make && \
	source connection.bash \
	  --bastion         $(BASTION)         \
	  --location        $(LOCATION)        \
	  --resource-group  $(RESOURCE_GROUP)  \
	  --virtual-machine $(VIRTUAL_MACHINE)

define handle_debug
	$(if $(filter $(DEBUG),yes),set -o xtrace;)
endef
