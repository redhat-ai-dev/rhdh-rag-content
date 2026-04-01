#!/usr/bin/env bash
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

set -euo pipefail

usage() {
    echo "Usage: $0 <vector_store_repository> <vector_store_ref> <llama_stack_version> <rhdh_docs_version>" >&2
    echo "" >&2
    echo "  vector_store_repository  Vector store repository URL (e.g. 'https://github.com/org/repo.git')" >&2
    echo "  vector_store_ref         Repository branch or ref to clone (e.g. 'main')" >&2
    echo "  llama_stack_version      Llama Stack version directory (e.g. '0.4.3')" >&2
    echo "  rhdh_docs_version        RHDH documentation version directory (e.g. '1.9')" >&2
    exit 1
}

if [ $# -ne 4 ]; then
    usage
fi

VECTOR_STORE_REPOSITORY="$1"
VECTOR_STORE_REF="$2"
LLAMA_STACK_VERSION="$3"
RHDH_DOCS_VERSION="$4"

git clone --depth=1 --branch "${VECTOR_STORE_REF}" "${VECTOR_STORE_REPOSITORY}" vector-stores

VECTOR_STORE_DIR="vector-stores/${LLAMA_STACK_VERSION}/vector_db"
DOCS_VECTOR_STORE_DIR="${VECTOR_STORE_DIR}/rhdh_product_docs/${RHDH_DOCS_VERSION}"

if [ ! -d "${VECTOR_STORE_DIR}" ]; then
    echo "Missing vector store directory for LLS version '${LLAMA_STACK_VERSION}' at '${VECTOR_STORE_DIR}'" >&2
    exit 1
fi

if [ ! -d "${DOCS_VECTOR_STORE_DIR}" ]; then
    echo "Missing vector store docs directory for RHDH version '${RHDH_DOCS_VERSION}' at '${DOCS_VECTOR_STORE_DIR}'" >&2
    exit 1
fi

mkdir -p /prepared/rag/vector_db/rhdh_product_docs
cp -a "${DOCS_VECTOR_STORE_DIR}" "/prepared/rag/vector_db/rhdh_product_docs/${RHDH_DOCS_VERSION}"
cp -a /rag-content/embeddings_model /prepared/rag/embeddings_model
