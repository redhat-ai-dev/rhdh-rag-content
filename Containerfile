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

FROM registry.access.redhat.com/ubi9/ubi-minimal:9.7@sha256:8d0a8fb39ec907e8ca62cdd24b62a63ca49a30fe465798a360741fde58437a23 AS rag-assets-downloader

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

FROM registry.access.redhat.com/ubi9/ubi-micro:9.7@sha256:e0b6e93fe3800bf75a3e95aaf63bdfd020ea6dc30a92ca4bfa0021fa28cd671a

COPY --from=rag-assets-downloader /tmp/rag-assets/extracted/vector_db/rhdh_product_docs /rag/vector_db/rhdh_product_docs
COPY --from=rag-assets-downloader /tmp/rag-assets/extracted/embeddings_model /rag/embeddings_model

USER 65532:65532
