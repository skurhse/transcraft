OUT_DIR = out
MIME_FILE = $(OUT_DIR)/cloud-init.mime

.PHONY: run
run:
	.scripts/$(NAME).bash

.PHONY: cloud-init-test
test-run: user-data
	.tests/cloud-init_test.bash

.PHONY: user-data
user-data: $(MIME_FILE)

$(MIME_FILE): $(OUT_DIR)
	cloud-init devel make-mime \
	  -a cloud-init/cloud-config/config.yaml:cloud-config \
	  -a cloud-init/x-shellscript/per-boot.bash:x-shellscript-per-boot \
	  -a cloud-init/x-shellscript/per-instance.bash:x-shellscript-per-instance \
	  -a cloud-init/x-shellscript/per-once.bash:x-shellscript-per-once \
	> $(OUT_DIR)/cloud-init.mime

$(OUT_DIR):
	mkdir -p $(OUT_DIR)