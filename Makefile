JMES = properties.outputs.minecraftPublicIP.value

GROUP = transcraft
DEPL = main

.PHONY: setup
setup:
	.scripts/setup.bash

.PHONY: pipeline
pipeline:
	.scripts/pipeline.bash

.PHONY: get-ip
get-ip:
	az deployment group show -g $(GROUP) -n $(DEPL) --query $(JMES) -o tsv

.PHONY: user-data
user-data:
	cloud-init devel -h
