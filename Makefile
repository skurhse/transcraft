# NOTE: To see a list of typical targets, execute `make help` <skr 2022-07>

SHELL = /usr/bin/env bash

# log levels:
LVLS = DEBUG INFO WARN ERROR FATAL
export LVL ?= WARN

# environments:
ENVS = development production
ENV ?= development

# resource group:
RG_NAME = transcraft
RG_LOC = centralus

# bastion:
BT_NAME = bastion-d4vxd4ztxl3dk-bh

# virtual machine:
VM_NAME = transcraft-d4vxd4ztxl3dk-vm

# service principal:
SP_NAME = github_actions

# directories:
OUT_DIR = out
SSH_DIR = $(OUT_DIR)/ssh

# ssh:
export SSH_PRIVATE_KEY = $(SSH_DIR)/id_rsa
export SSH_PUBLIC_KEY = $(SSH_PRIVATE_KEY).pub

# cloud-init:
export MIME_FILE = $(OUT_DIR)/cloud-init.mime

# cleaning targets:
.PHONY: clean reset
clean:
	rm -v $(MIME_FILE)

reset: clean
	rm -v $(SSH_PRIVATE_KEY) $(SSH_PUBLIC_KEY)

# build targets:
.PHONY: dirs ssh-keys user-data

dirs: $(SSH_DIR)
$(SSH_DIR):
	mkdir -p $(SSH_DIR)

ssh-keys: $(SSH_PUBLIC_KEY) $(SSH_PRIVATE_KEY)
$(SSH_PRIVATE_KEY) $(SSH_PUBLIC_KEY) &:
	make/ssh-keys.bash

user-data: $(MIME_FILE)
$(MIME_FILE): $(OUT_DIR) cloud-init/*/*
	make/mime-file.bash

# utility targets:
.PHONY: connection deployment

connection: validate_log_level
	cd make && ./connection.bash -b $(BT_NAME) -l $(RG_LOC) -g $(RG_NAME) -m $(VM_NAME)

deployment: $(MIME_FILE)
	cd make && ./deployment.bash

# miscellanous targets:
.PHONY: help validate-log-level

help:
	@echo 'Cleaning targets:'
	@echo ' clean       - Remove most generated files, but keep ssh keys.'
	@echo ' reset       - Remove all generated files.'
	@echo ''
	@echo 'Build targets:'
	@echo '  all        - Build all targets.'
	@echo '  dirs 		  - Build directories.'
	@echo '  ssh-keys   - Build SSH keys.'
	@echo '  user-data  - Build user-data.'
	@echo ''
	@echo 'Utility targets:'
	@echo '  connection - Connect to the virtual machine through a bastion ssh tunnel.'
	@echo ''
	@echo 'Miscellaneous targets:'
	@echo '  help               - Display this usage text.'
	@echo '  validate-log-level - Validate the log level.'
	@echo ''

validate_log_level:
ifneq ($(filter $(LVL),$(LVLS)),)
	$(info Log level $(LVL) is valid.)
else
	@echo "Log level is invalid. Valid values are: $(LVLS)"
	@exit 1
	$(error Log level $(LVL) is invalid.)
endif
