# NOTE: To see a list of typical targets, execute `make help` <>

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
RG_NAME = tulip
RG_LOC = centralus

# bastion:
BT_NAME = lilac

# virtual machine:
VM_NAME = peony

# service principal:
SP_NAME = github_actions

# ssh:
SSH_DIR = $(ENV_DIR)/ssh
export SSH_PRIVATE_KEY = $(SSH_DIR)/id_rsa
export SSH_PUBLIC_KEY = $(SSH_PRIVATE_KEY).pub

# cloud-init:
MIME_DIR = $(ENV_DIR)/mime
export MIME_FILE = $(MIME_DIR)/cloud-init.mime

# cleaning targets:
.PHONY: clean reset
clean:
	rm -fv $(MIME_FILE)

reset: clean
	rm -fv $(SSH_PRIVATE_KEY) $(SSH_PUBLIC_KEY)

# build targets:
.PHONY: all dirs keyfiles mimefile

all: dirs keyfiles mimefile

dirs: $(SSH_DIR) $(MIME_DIR)
$(SSH_DIR):
	mkdir -p $(SSH_DIR)

$(MIME_DIR):
	mkdir -p $(MIME_DIR)

keyfiles: $(SSH_PUBLIC_KEY) $(SSH_PRIVATE_KEY)
$(SSH_PRIVATE_KEY) $(SSH_PUBLIC_KEY) &: $(SSH_DIR)
	make/build/keyfiles.bash -e $(ENV) -k $(SSH_PRIVATE_KEY)

mimefile: $(MIME_FILE)
$(MIME_FILE): $(MIME_DIR) cloud-init/*/*
	make/build/mimefile.bash -u $(MIME_FILE)

# utility targets:
.PHONY: prereqs connection deployment

prereqs: validate_log_level
	make/util/prereqs.bash

conn: validate_log_level
	make/util/conn.bash -b $(BT_NAME) -l $(RG_LOC) -g $(RG_NAME) -m $(VM_NAME)

deploy: validate_log_level $(MIME_FILE)
	make/util/deploy.bash -b $(BT_NAME) -l $(RG_LOC) -g $(RG_NAME) -m $(VM_NAME)

# miscellanous targets:
.PHONY: help validate-log-level

help:
	@echo 'Cleaning targets:'
	@echo ' clean       - Remove most generated files per env, but keep keyfiles.'
	@echo ' reset       - Remove all generated files per env.'
	@echo ''
	@echo 'Build targets:'
	@echo '  all        - Build all targets per env.'
	@echo '  dirs 		  - Build output directories.'
	@echo '  keyfiles   - Build ssh keyfiles per env.'
	@echo '  mimefile   - Build the cloud-init mimefile per env.'
	@echo ''
	@echo 'Utility targets:'
	@echo '  prereqs    - Install prerequisites.'
	@echo '  conn       - Connect to an env virtual machine thru a bastion ssh tunnel.'
	@echo '  deploy     - Deploy an environment.'
	@echo ''
	@echo 'Miscellaneous targets:'
	@echo '  help               - Display this usage text.'
	@echo '  validate-log-level - Validate the log level.'
	@echo ''

validate_log_level:
ifeq ($(filter $(LVL),$(LVLS)),)
	$(error Log level $(LVL) is invalid.)
endif
