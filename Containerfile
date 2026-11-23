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
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.9-1795001629@sha256:d8162789d7913ef8941481687b92ab4bbec311870948f66cf52b9cc7e0c57c06 AS rag-assets-downloader

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
FROM registry.access.redhat.com/ubi9/ubi-micro:9.9-1794478307@sha256:dbd325b96bcd432dd42816d31412bdf1dc0fb973b79ed310344bc23c76c068db

COPY --from=rag-assets-downloader /tmp/rag-assets/extracted/vector_db/rhdh_product_docs /rag/vector_db/rhdh_product_docs
COPY --from=rag-assets-downloader /tmp/rag-assets/extracted/embeddings_model /rag/embeddings_model

USER 65532:65532
