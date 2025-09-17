# Default to CPU if not specified
FLAVOR ?= cpu
NUM_WORKERS ?= $$(( $(shell nproc --all) / 2))

# Define behavior based on the flavor
ifeq ($(FLAVOR),cpu)
TORCH_GROUP := cpu
else ifeq ($(FLAVOR),gpu)
TORCH_GROUP := gpu
else
$(error Unsupported FLAVOR $(FLAVOR), must be 'cpu' or 'gpu')
endif

build-image-rhdh-example: ## Build a rag-content container image for RHDH
	podman build --platform linux/amd64 -t rhdh-rag-content -f Containerfile.rhdh_lightspeed --build-arg FLAVOR=$(TORCH_GROUP) .

help: ## Show this help screen
	@echo 'Usage: make <OPTIONS> ... <TARGETS>'
	@echo ''
	@echo 'Available targets are:'
	@echo ''
	@grep -E '^[ a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ''
