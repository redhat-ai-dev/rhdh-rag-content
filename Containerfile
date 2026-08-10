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

# https://registry.access.redhat.com/ubi9/ubi-minimal
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.8-1786323074@sha256:57c8151c51445a07e503dab9dc9211dc3cdeac9d45ed81a10954b7d770659b3b AS rag-assets-downloader

ARG RAG_ASSETS_URL

USER 0
WORKDIR /tmp/rag-assets

RUN microdnf install -y tar gzip && microdnf clean all
RUN test -n "${RAG_ASSETS_URL}" && \
    curl -fsSL "${RAG_ASSETS_URL}" -o rag-assets.tar.gz && \
    mkdir -p extracted && \
    tar --no-same-owner --no-same-permissions -C extracted -xzf rag-assets.tar.gz && \
    test -d extracted/vector_db/rhdh_product_docs && \
    test -d extracted/embeddings_model

# https://registry.access.redhat.com/ubi9/ubi-micro
FROM registry.access.redhat.com/ubi9/ubi-micro:9.8-1786321990@sha256:7e7f79ab747bf2b452e3043dd89f388e92be4c7fdcc8b815b58adf6c99c39c95

COPY --from=rag-assets-downloader /tmp/rag-assets/extracted/vector_db/rhdh_product_docs /rag/vector_db/rhdh_product_docs
COPY --from=rag-assets-downloader /tmp/rag-assets/extracted/embeddings_model /rag/embeddings_model

USER 65532:65532
