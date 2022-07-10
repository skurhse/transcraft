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

# general:
ALL_FILES = $(MIME_FILE) $(SSH_KEYFILES)
VALIDATIONS = validate-log-level validate-environment

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

resource-group: $(VALIDATIONS)
	make/deploy/resource-group.bash -g $(RG_NAME) -l $(RG_LOC)

service-principal: $(VALIDATIONS)
	make/deploy/service.bash -g $(RG_NAME) -l $(RG_LOC)

arm-deployment: validate-log-level $(ALL_FILES)
	make/deploy/deploy.bash -b $(BT_NAME) -l $(RG_LOC) -g $(RG_NAME) -m $(VM_NAME)

# utility targets:
.PHONY: prequisites connection

prequisites: validate-log-level
	make/util/prequisites.bash

connection: validate-log-level
	make/util/connection.bash -b $(BT_NAME) -l $(RG_LOC) -g $(RG_NAME) -m $(VM_NAME)

# miscellanous targets:
.PHONY: help validate-log-level validate-environment

help:
	@echo 'Clean targets:'
	@echo ' reset                 - Remove all generated files.'
	@echo ' clean                 - Remove most generated files, but keep keyfiles.'
	@echo ''
	@echo 'Build targets:'
	@echo '  all                  - Build all targets.'
	@echo '  dirs                 - Build output directories.'
	@echo '  keyfiles             - Build ssh keyfiles.'
	@echo '  mimefile             - Build a cloud-init mimefile.'
	@echo ''
	@echo 'Deploy targets:'
	@echo '  arm-deployment       - Deploy a $(PROJECT) environment.'
	@echo '  resource-group       - Create an environment resource group.'
	@echo '  service-principal    - Create an environment service principal.'
	@echo
	@echo 'Utility targets:'
	@echo '  connection           - Create a bastion ssh tunnel.'
	@echo '  prequisites          - Install project prerequisites.'
	@echo ''
	@echo 'Miscellaneous targets:'
	@echo '  help                 - Display this usage text.'
	@echo '  validate-log-level   - Validate the log level.'
	@echo '  validate-environment - Validate the environment.'
	@echo ''

validate-log-level:
ifeq ($(filter $(LVL),$(LVLS)),)
	$(error Log level $(LVL) is invalid.)
endif

validate-environment:
ifeq ($(filter $(ENV),$(ENVS)),)
	$(error Environment $(ENV) is invalid.)
endif