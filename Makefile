# NOTE: To see a list of typical targets, execute `make help` <>

PROJECT = transcraft
SHELL = /usr/bin/env bash
OUT_DIR = out

# log levels:
LVLS = debug info warn error fatal
export LVL ?= warn

# environments:
ENVS = dev prod
ENV ?= dev
ENV_DIR = $(OUT_DIR)/$(ENV)

# resource group:
RG_NAME = $(PROJECT)-$(ENV)
RG_LOC = centralus

# bastion:
BT_NAME = tulip-$(ENV)

# virtual machine:
VM_NAME = lilac-$(ENV)

# service principal:
SP_NAME = github_actions

# ssh:
SSH_DIR = $(ENV_DIR)/ssh
export SSH_PRIVATE_KEY = $(SSH_DIR)/id_rsa
export SSH_PUBLIC_KEY = $(SSH_PRIVATE_KEYFILE).pub
SSH_KEYFILES = $(SSH_PRIVATE_KEYFILE) $(SSH_PUBLIC_KEYFILE)

# cloud-init:
MIME_DIR = $(ENV_DIR)/mime
export MIME_FILE = $(MIME_DIR)/cloud-init.mime

ALL_FILES = $(MIME_FILE) $(SSH_KEYFILES)

# cleaning targets:
.PHONY: clean reset
clean:
	rm -fv $(MIME_FILE)

reset: clean
	rm -fv $(SSH_KEYFILES)

# build targets:
.PHONY: all dirs keyfiles mimefile

all: dirs keyfiles mimefile

dirs: $(SSH_DIR) $(MIME_DIR)
$(SSH_DIR):
	mkdir -p $(SSH_DIR)

$(MIME_DIR):
	mkdir -p $(MIME_DIR)

keyfiles: $(SSH_KEYFILES)
$(SSH_KEYFILES) &: $(SSH_DIR)
	make/build/keyfiles.bash -e $(ENV) -k $(SSH_PRIVATE_KEYFILE)

mimefile: $(MIME_FILE)
$(MIME_FILE): $(MIME_DIR) cloud-init/*/*
	make/build/mimefile.bash -u $(MIME_FILE)

# deployment targets:
.PHONY: resource-group service-principal arm-deployment

resource-group:
	make/deploy/group.bash -g $(RG_NAME) -l $(RG_LOC)

service-principal:
	make/deploy/service.bash -g $(RG_NAME) -l $(RG_LOC)

arm-deployment: validate_log_level $(ALL_FILES)
	make/deploy/deploy.bash -b $(BT_NAME) -l $(RG_LOC) -g $(RG_NAME) -m $(VM_NAME)

# utility targets:
.PHONY: prequisites connection

prequisites: validate_log_level
	make/util/prequisites.bash

connection: validate_log_level
	make/util/connection.bash -b $(BT_NAME) -l $(RG_LOC) -g $(RG_NAME) -m $(VM_NAME)

# miscellanous targets:
.PHONY: help validate-log-level

help:
	@echo 'Clean targets:'
	@echo ' reset               - Remove all generated files per environment.'
	@echo ' clean               - Remove most generated files per environment, but keep keyfiles.'
	@echo ''
	@echo 'Build targets:'
	@echo '  all                - Build all targets per environment.'
	@echo '  dirs               - Build output directories per environment.'
	@echo '  keyfiles           - Build ssh keyfiles per environment.'
	@echo '  mimefile           - Build the cloud-init mimefile per environment.'
	@echo ''
	@echo 'Deploy targets:'
	@echo '  arm-deployment     - Deploy a $(PROJECT) environment.'
	@echo '  resource-group     - Create an environment resource group.'
	@echo '  service-principal  - Create an environment service principal.'
	@echo
	@echo 'Utility targets:'
	@echo '  connection         - Connect to an env virtual machine thru a bastion ssh tunnel.'
	@echo '  prequisites        - Install prerequisites.'
	@echo ''
	@echo 'Miscellaneous targets:'
	@echo '  help               - Display this usage text.'
	@echo '  validate-log-level - Validate the log level.'
	@echo ''

validate_log_level:
ifeq ($(filter $(LVL),$(LVLS)),)
	$(error Log level $(LVL) is invalid.)
endif
