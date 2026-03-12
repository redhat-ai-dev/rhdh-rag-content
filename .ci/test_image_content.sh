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

IMAGE="${1:?Usage: $0 <image-name>}"

PASS=0
FAIL=0
TMPDIR=""
CONTAINER_ID=""

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

cleanup() {
    if [ -n "$CONTAINER_ID" ]; then
        docker rm -f "$CONTAINER_ID" >/dev/null 2>&1 || true
    fi
    if [ -n "$TMPDIR" ]; then
        rm -rf "$TMPDIR"
    fi
}
trap cleanup EXIT

echo "=== Image Content Smoke Tests ==="
echo "Image: ${IMAGE}"
echo ""

CONTAINER_ID=$(docker create "$IMAGE")
TMPDIR=$(mktemp -d)

docker cp "${CONTAINER_ID}:/rag/embeddings_model" "${TMPDIR}/embeddings_model"
docker cp "${CONTAINER_ID}:/rag/vector_db" "${TMPDIR}/vector_db"

# --- Test: Embedding model directory is not empty ---
echo "--- Embedding Model ---"
FILE_COUNT=$(find "${TMPDIR}/embeddings_model" -type f | wc -l)
if [ "$FILE_COUNT" -gt 0 ]; then
    pass "Embedding model directory contains ${FILE_COUNT} file(s)"
else
    fail "Embedding model directory is empty"
fi

# --- Test: At least one version directory exists ---
echo "--- Vector Store ---"
VERSION_DIRS=()
for dir in "${TMPDIR}/vector_db/rhdh_product_docs"/*/; do
    [ -d "$dir" ] && VERSION_DIRS+=("$dir")
done

if [ "${#VERSION_DIRS[@]}" -gt 0 ]; then
    pass "Found ${#VERSION_DIRS[@]} version directory(ies)"
else
    fail "No version directories found under vector_db/rhdh_product_docs/"
fi

# --- Test each version directory ---
for vdir in "${VERSION_DIRS[@]}"; do
    VERSION=$(basename "$vdir")
    echo "--- Version: ${VERSION} ---"

    DB_FILE="${vdir}/faiss_store.db"
    if [ -f "$DB_FILE" ] && [ -s "$DB_FILE" ]; then
        pass "faiss_store.db exists and is non-empty"
    else
        fail "faiss_store.db missing or empty for version ${VERSION}"
        continue
    fi

    # Extract the chunk_by_index object and count its keys
    CHUNK_JSON=$(sqlite3 "$DB_FILE" "SELECT value FROM kvstore WHERE key LIKE '%faiss_index%' LIMIT 1;")
    if [ -z "$CHUNK_JSON" ]; then
        fail "No faiss_index row found in kvstore for version ${VERSION}"
        continue
    fi

    CHUNK_COUNT=$(echo "$CHUNK_JSON" | jq '.chunk_by_index | length')
    if [ "$CHUNK_COUNT" -gt 0 ]; then
        pass "Vector store contains ${CHUNK_COUNT} chunk(s)"
    else
        fail "Vector store has 0 chunks for version ${VERSION}"
    fi
done

# --- Summary ---
echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
