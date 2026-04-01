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
ARG BASE_IMAGE=quay.io/lightspeed-core/rag-content-cpu@sha256:297db4e12b07dcf460b1b5186764f32b6bb41841d77d085aa5e650e30f7b9031
FROM ${BASE_IMAGE} AS lightspeed-core-rag-builder
ARG RHDH_DOCS_VERSION="1.9"
ARG LLAMA_STACK_VERSION="0.4.3"
ARG VECTOR_STORE_REPOSITORY="https://github.com/redhat-ai-dev/rhdh-vector-stores.git"
ARG VECTOR_STORE_REF="main"

USER 0
WORKDIR /rag-content


RUN set -euo pipefail && \
    git clone --depth=1 --branch "${VECTOR_STORE_REF}" "${VECTOR_STORE_REPOSITORY}" vector-stores && \
    VECTOR_STORE_DIR="vector-stores/${LLAMA_STACK_VERSION}/vector_db" && \
    DOCS_VECTOR_STORE_DIR="${VECTOR_STORE_DIR}/rhdh_product_docs/${RHDH_DOCS_VERSION}" && \
    if [ ! -d "${VECTOR_STORE_DIR}" ]; then \
      echo "Missing vector store directory for LLS version '${LLAMA_STACK_VERSION}' at '${VECTOR_STORE_DIR}'" >&2; \
      exit 1; \
    fi && \
    if [ ! -d "${DOCS_VECTOR_STORE_DIR}" ]; then \
      echo "Missing vector store docs directory for RHDH version '${RHDH_DOCS_VERSION}' at '${DOCS_VECTOR_STORE_DIR}'" >&2; \
      exit 1; \
    fi && \
    mkdir -p /prepared/rag/vector_db /prepared/rag && \
    mkdir -p /prepared/rag/vector_db/rhdh_product_docs && \
    cp -a "${DOCS_VECTOR_STORE_DIR}" "/prepared/rag/vector_db/rhdh_product_docs/${RHDH_DOCS_VERSION}" && \
    cp -a /rag-content/embeddings_model /prepared/rag/embeddings_model

FROM registry.access.redhat.com/ubi9/ubi-minimal:9.7@sha256:161a4e29ea482bab6048c2b36031b4f302ae81e4ff18b83e61785f40dc576f5d
COPY --from=lightspeed-core-rag-builder /prepared/rag/vector_db/rhdh_product_docs /rag/vector_db/rhdh_product_docs
COPY --from=lightspeed-core-rag-builder /prepared/rag/embeddings_model /rag/embeddings_model

USER 65532:65532
