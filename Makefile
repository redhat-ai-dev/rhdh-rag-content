#
#
# Copyright Red Hat
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FLAVOR ?= cpu
LLAMA_STACK_VERSION ?= latest
RHDH_DOCS_VERSION ?= 1.9
NUM_WORKERS ?= $$(( $(shell nproc --all) / 2))
PLATFORM ?= linux/amd64
IMAGE_NAME ?= rhdh-rag-content

BASE_IMAGE := $(shell ./scripts/resolve-base-image.sh "$(LLAMA_STACK_VERSION)" "$(FLAVOR)")

build-image: ## Build the container image
	podman build --platform ${PLATFORM} -t ${IMAGE_NAME} -f Containerfile --build-arg BASE_IMAGE=$(BASE_IMAGE) --build-arg RHDH_DOCS_VERSION=$(RHDH_DOCS_VERSION) .

help: ## Show this help screen
	@echo 'Usage: make <OPTIONS> ... <TARGETS>'
	@echo ''
	@echo 'Available targets are:'
	@echo ''
	@grep -E '^[ a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ''
