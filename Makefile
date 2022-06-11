JMES = properties.outputs.minecraftPublicIP.value

GROUP = transcraft
DEPL = main

.PHONY: pipeline
pipeline:
	.scripts/pipeline.bash

.PHONY: get-ip
get-ip:
	az deployment group show -g $(GROUP) -n $(DEPL) --query $(JMES) -o tsv
