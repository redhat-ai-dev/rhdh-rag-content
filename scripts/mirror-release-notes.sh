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

# NOTE: You must be logged into the VPN to use this script.

set -euo pipefail

GITLAB_REPO="https://gitlab.cee.redhat.com/red-hat-developers-documentation/red-hat-developer-hub-release-notes.git"
GITHUB_REPO="https://github.com/redhat-ai-dev/release-notes-mirror.git"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "Cloning from GitLab (requires VPN)..."
git clone --mirror "$GITLAB_REPO" "$TMPDIR/mirror.git"

echo "Pushing to GitHub..."
cd "$TMPDIR/mirror.git"
git push --mirror "$GITHUB_REPO"

echo "Mirror complete."
