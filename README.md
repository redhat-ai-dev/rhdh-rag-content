# RHDH RAG CONTENT

[![Apache2.0 License](https://img.shields.io/badge/license-Apache2.0-brightgreen.svg)](LICENSE)

> [!NOTE]
> The `main` branch hosts the RHDH RAG logic compatible with LCORE's [rag-content](https://github.com/lightspeed-core/rag-content).
> 

## Overview

This repository produces Red Hat Developer Hub (RHDH) Lightspeed RAG content container images. Images are built on top of the upstream [`lightspeed-core/rag-content`](https://github.com/lightspeed-core/rag-content) base images, with the specific upstream image tag determined by the selected llama stack version via [`ci-versions.json`](ci-versions.json).

The container images are published to [redhat-ai-dev/rag-content](https://quay.io/repository/redhat-ai-dev/rag-content?tab=tags) on Quay.io.

## CI / Building Images

Container images are built and pushed through a GitHub Actions workflow triggered manually from the **Actions** tab (`workflow_dispatch`).

### Workflow Inputs

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | yes | RHDH documentation version, e.g. `1.8` |
| `compute_flavor` | choice (`cpu` / `gpu`) | no (default: `cpu`) | Compute flavor for the container build |
| `llama_stack_version` | string | yes | A llama stack version key from `ci-versions.json`, e.g. `0.4.3` or `latest` for experimental |

### How It Works

1. The workflow reads `ci-versions.json` and looks up the `lightspeed_rag_content_tag` for the given `llama_stack_version`.
2. That tag is passed as the `TAG` build arg to the Containerfile, which pulls the corresponding upstream `quay.io/lightspeed-core/rag-content-{flavor}:{tag}` base image.
3. If `latest` is selected as the llama stack version, the resulting image is tagged with `experimental` to signal that it tracks an upstream moving target and may be unstable.

### Image Tags

The resulting multi-arch (amd64/arm64) images are tagged as:

```
release-<doc_version>-lls-<llama_stack_version | experimental>
```

Examples:

- `release-1.8-lls-0.4.3` — stable build pinned to llama stack 0.4.3
- `release-1.8-lls-0.3.5` — stable build pinned to llama stack 0.3.5
- `release-1.8-lls-experimental` — built from upstream `latest`, may be unstable

A SHA-preserved tag is also pushed for every build for historic image preservation:

- `release-1.8-lls-0.4.3-<github_sha>`
- `release-1.8-lls-experimental-<github_sha>`

## ci-versions.json

The [`ci-versions.json`](ci-versions.json) file is the single source of truth for mapping llama stack versions to upstream base image tags.

### Structure

```json
{
    "images": {
        "0.3.5": {
            "lightspeed_rag_content_tag": "dev-20260123-60036ff"
        },
        "0.4.3": {
            "lightspeed_rag_content_tag": "dev-20260130-1c38b94"
        },
        "latest": {
            "lightspeed_rag_content_tag": "latest"
        }
    }
}
```

- Each key under `images` is a llama stack version (e.g. `0.3.5`, `0.4.3`, `latest`).
- `lightspeed_rag_content_tag` is the image tag for the upstream `quay.io/lightspeed-core/rag-content-{flavor}` image.
- The `latest` entry tracks the upstream `latest` tag and is considered experimental / potentially unstable.

### Adding a New Llama Stack Version

To add support for a new llama stack version, add a new entry under `images` with the version as the key and the pinned upstream image tag:

```json
"0.5.0": {
    "lightspeed_rag_content_tag": "dev-20260215-abc1234"
}
```

Then trigger the workflow with `llama_stack_version` set to `0.5.0`.

## Release Strategy

- **Future release branches** (cut from `main` after this CI change) carry their own copy of `ci-versions.json` pinned to the llama stack versions validated for that release.
- **Existing release branches** (pre-refactor) retain the old workflow with the `experimental` boolean and are unaffected.
- **Cutting a new release**: branch from `main`, review `ci-versions.json`, and lock it to only the versions that are known-good for that release (i.e., remove `latest` if desired).
- **Rebuilding a historic image**: navigate to the release branch in GitHub and trigger the workflow. The workflow reads the branch's own `ci-versions.json`, ensuring the correct upstream image tags are used.

## Local Development

The `pyproject.toml` and `uv.lock` files are maintained for local development use. They install the upstream `lightspeed-rag-content` package so you can run the Python scripts locally without needing a container.

### Setup

1. **Update the upstream dependency** — edit `pyproject.toml` and update the `lightspeed-rag-content` git reference to the desired upstream commit hash:

   ```toml
   dependencies = [
       "lightspeed-rag-content @ git+https://github.com/lightspeed-core/rag-content@<commit_hash>",
       "pyyaml",
   ]
   ```

2. **Sync dependencies**:

   ```bash
   uv sync
   ```

3. **Activate the virtual environment** and run the Python scripts as needed:

   ```bash
   source .venv/bin/activate
   ```

### Building a Container Image Locally

To build a container image locally using the Makefile:

```bash
make build-image
```

This defaults to `cpu` flavor. To build for GPU:

```bash
make build-image FLAVOR=gpu
```

## Verifying Vector Database

After building the container image, you can inspect and query the generated vector database to verify its contents.

### Building the Builder Stage

The final container image is minimal and only contains the vector database files. To run verification scripts, build the builder stage which includes Python and all dependencies:

```bash
podman build --platform linux/arm64 \
    --target lightspeed-core-rag-builder \
    -t rhdh-rag-builder \
    -f Containerfile \
    --build-arg FLAVOR=cpu .
```

Then start an interactive shell:

```bash
podman run --rm -it rhdh-rag-builder /bin/bash
```

### Inspecting the Vector Database

Use `inspect_vector_db.py` to view statistics and contents of the vector database:

```bash
# Basic statistics (chunk count, text stats, config info)
python inspect_vector_db.py -p vector_db/rhdh_product_docs/1.8

# Show sample chunks with readable text
python inspect_vector_db.py -p vector_db/rhdh_product_docs/1.8 --sample 3

# Export all chunks to JSON
python inspect_vector_db.py -p vector_db/rhdh_product_docs/1.8 --list-chunks --json > chunks.json

# Full JSON output (stats only)
python inspect_vector_db.py -p vector_db/rhdh_product_docs/1.8 --json
```

#### Options

| Flag | Description |
|------|-------------|
| `-p, --db-path` | Path to the vector database directory (required) |
| `--sample N` | Show N sample chunks with readable content |
| `--list-chunks` | Output all chunks |
| `--json` | Output in JSON format |

### Querying the Vector Database

Use `query_rag.py` to test retrieval from the vector database:

```bash
# Basic query
python query_rag.py \
    -p vector_db/rhdh_product_docs/1.8 \
    -x rhdh-product-docs-1_8 \
    -m embeddings_model \
    -q "What is Red Hat Developer Hub?" \
    -k 5

# Query with score threshold
python query_rag.py \
    -p vector_db/rhdh_product_docs/1.8 \
    -x rhdh-product-docs-1_8 \
    -m embeddings_model \
    -q "How do I install plugins?" \
    -k 3 \
    -t 0.5

# JSON output for programmatic use
python query_rag.py \
    -p vector_db/rhdh_product_docs/1.8 \
    -x rhdh-product-docs-1_8 \
    -m embeddings_model \
    -q "What is Lightspeed?" \
    --json
```

#### Options

| Flag | Description |
|------|-------------|
| `-p, --db-path` | Path to the vector database directory (required) |
| `-x, --product-index` | Product index ID, e.g., `rhdh-product-docs-1_8` (required) |
| `-m, --model-path` | Path to the embedding model (required) |
| `-q, --query` | Query string (required) |
| `-k, --top-k` | Number of results to return (default: 1) |
| `-t, --threshold` | Minimum score threshold for results (default: 0.0) |
| `-n, --node` | Retrieve a specific node by ID |
| `--json` | Output in JSON format |
