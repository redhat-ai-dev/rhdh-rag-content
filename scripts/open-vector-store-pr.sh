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

# Syncs a vector DB artifact into a target repository and opens a pull request.
# Requires: git, gh (GitHub CLI), rsync
# Expects GH_TOKEN to be set in the environment for gh authentication.

set -euo pipefail

usage() {
    echo "Usage: $0 <llama_stack_version> <rhdh_version> <target_repo> <target_branch> <run_id> <source_repository> <vector_db_source> <target_repo_path>" >&2
    echo "" >&2
    echo "  llama_stack_version  Llama Stack version (e.g. '0.4.3')" >&2
    echo "  rhdh_version         RHDH documentation version (e.g. '1.8')" >&2
    echo "  target_repo          Target GitHub repository (e.g. 'org/repo')" >&2
    echo "  target_branch        Base branch for the PR (e.g. 'main')" >&2
    echo "  run_id               Unique run identifier for the branch name" >&2
    echo "  source_repository    Source repository for the PR body link (e.g. 'org/source-repo')" >&2
    echo "  vector_db_source     Path to the downloaded vector DB artifact directory" >&2
    echo "  target_repo_path     Path to the checked-out target repository" >&2
    exit 1
}

if [ $# -ne 8 ]; then
    usage
fi

LLAMA_STACK_VERSION="$1"
RHDH_VERSION="$2"
TARGET_REPO="$3"
TARGET_BRANCH="$4"
RUN_ID="$5"
SOURCE_REPOSITORY="$6"
VECTOR_DB_SOURCE="$7"
TARGET_REPO_PATH="$8"

VERSIONED_DESTINATION="${LLAMA_STACK_VERSION}/vector_db"
BRANCH_NAME="bot/vector-db-${RHDH_VERSION}-lls-${LLAMA_STACK_VERSION}-${RUN_ID}"
PR_TITLE="Update vector_db for RHDH ${RHDH_VERSION} (LLS ${LLAMA_STACK_VERSION})"

mkdir -p "${TARGET_REPO_PATH}/${VERSIONED_DESTINATION}"
rsync -a --delete "${VECTOR_DB_SOURCE}/" "${TARGET_REPO_PATH}/${VERSIONED_DESTINATION}/"

cd "${TARGET_REPO_PATH}"

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

git checkout -b "${BRANCH_NAME}"
git add "${VERSIONED_DESTINATION}"

git commit -m "${PR_TITLE}"
git push --set-upstream origin "${BRANCH_NAME}"

PR_URL=$(gh pr create \
    --repo "${TARGET_REPO}" \
    --base "${TARGET_BRANCH}" \
    --head "${BRANCH_NAME}" \
    --title "${PR_TITLE}" \
    --body "Automated vector DB update from https://github.com/${SOURCE_REPOSITORY}/actions/runs/${RUN_ID}")

echo "Created PR: ${PR_URL}"
