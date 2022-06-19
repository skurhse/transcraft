JMES = properties.outputs.minecraftPublicIP.value

GROUP = transcraft
DEPL = main

OUT_DIR = out

out:
	mkdir -p $(OUT_DIR)

.PHONY: get-ip
get-ip:
	az deployment group show -g $(GROUP) -n $(DEPL) --query $(JMES) -o tsv

.PHONY: pipeline
pipeline:
	.scripts/pipeline.bash

.PHONY: setup
setup:
	.scripts/setup.bash

.PHONY: test
test: user-data
	.tests/cloud-init_test.bash

.PHONY: user-data
user-data: out
	cloud-init devel make-mime \
	  -a cloud-init/cloud-config/config.yaml:cloud-config \
	  -a cloud-init/x-shellscript/per-boot.bash:x-shellscript-per-boot \
	  -a cloud-init/x-shellscript/per-instance.bash:x-shellscript-per-instance \
	  -a cloud-init/x-shellscript/per-once.bash:x-shellscript-per-once \
	> $(OUT_DIR)/cloud-init.mime
