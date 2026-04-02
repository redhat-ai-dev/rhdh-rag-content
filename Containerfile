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

COPY scripts/prepare-vector-store.sh scripts/prepare-vector-store.sh
RUN ./scripts/prepare-vector-store.sh \
    "${VECTOR_STORE_REPOSITORY}" \
    "${VECTOR_STORE_REF}" \
    "${LLAMA_STACK_VERSION}" \
    "${RHDH_DOCS_VERSION}"

FROM registry.access.redhat.com/ubi9/ubi-minimal:9.7@sha256:161a4e29ea482bab6048c2b36031b4f302ae81e4ff18b83e61785f40dc576f5d
COPY --from=lightspeed-core-rag-builder /prepared/rag/vector_db/rhdh_product_docs /rag/vector_db/rhdh_product_docs
COPY --from=lightspeed-core-rag-builder /prepared/rag/embeddings_model /rag/embeddings_model

USER 65532:65532
