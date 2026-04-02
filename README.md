# RHDH RAG CONTENT

[![Apache2.0 License](https://img.shields.io/badge/license-Apache2.0-brightgreen.svg)](LICENSE)

> [!NOTE]
> The `main` branch hosts the RHDH RAG logic compatible with LCORE's [rag-content](https://github.com/lightspeed-core/rag-content).
> 

## Overview

This repository produces Red Hat Developer Hub (RHDH) Lightspeed RAG content container images. Images are built on top of the upstream [`lightspeed-core/rag-content`](https://github.com/lightspeed-core/rag-content) base images, with the specific upstream image tag determined by the selected llama stack version via [`versions.json`](versions.json).

The container images are published to [redhat-ai-dev/rag-content](https://quay.io/repository/redhat-ai-dev/rag-content?tab=tags) on Quay.io.

Pre-generated vector stores are stored in a separate repository: [`redhat-ai-dev/rhdh-vector-stores`](https://github.com/redhat-ai-dev/rhdh-vector-stores).

## CI Workflows

There are two GitHub Actions workflows, both triggered manually via `workflow_dispatch`.

### 1. Generate and PR Vector Store (`gen-vector-store.yml`)

Generates a vector store from RHDH documentation and opens a pull request to the [vector-stores repository](https://github.com/redhat-ai-dev/rhdh-vector-stores) with the result.

#### Inputs

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | yes | RHDH documentation version, e.g. `1.9` |
| `llama_stack_version` | string | yes | Llama stack version key from `versions.json`, e.g. `0.4.3` or `latest` |

#### How It Works

1. Resolves the upstream base image from `versions.json` for the given `llama_stack_version`.
2. Builds `Containerfile.vs` which generates embeddings and the vector database inside the container.
3. Extracts the `/rag/vector_db` directory from the built image.
4. Clones the vector-stores repository, places the extracted content under `<llama_stack_version>/vector_db/`, and opens a PR.

The resulting PR places files in the vector-stores repo at:

```
<llama_stack_version>/vector_db/rhdh_product_docs/<RHDH_DOCS_VERSION>/
```

### 2. Build and Push RAG Container (`build-and-push.yml`)

Builds the final multi-arch container image and pushes it to Quay.io.

> [!IMPORTANT]
> The vector store for the target `llama_stack_version` and `version` must already exist in the [vector-stores repository](https://github.com/redhat-ai-dev/rhdh-vector-stores). If it does not, run the **Generate and PR Vector Store** workflow first and merge the resulting PR before building.

#### Inputs

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | yes | RHDH documentation version, e.g. `1.9` |
| `llama_stack_version` | string | yes | Llama stack version key from `versions.json`, e.g. `0.4.3` or `latest` |

#### How It Works

1. Resolves the upstream CPU base image from `versions.json` for the given `llama_stack_version`.
2. Builds `Containerfile` which clones the vector-stores repo at `main` (or a configurable ref for release builds), validates that the expected vector store directory exists, and copies the vector DB and embeddings model into a minimal UBI image.
3. Pushes architecture-specific images (amd64 + arm64) to Quay.io.
4. Creates and pushes multi-arch manifests.

The build will **fail** if the vector store for the requested `llama_stack_version` and `version` is not present in the vector-stores repo.

### Image Tags

The resulting multi-arch (amd64/arm64) images are tagged as:

```
release-<doc_version>-lls-<llama_stack_version | experimental>
```

Examples:

- `release-1.9-lls-0.4.3` — stable build pinned to llama stack 0.4.3
- `release-1.9-lls-0.3.5` — stable build pinned to llama stack 0.3.5
- `release-1.9-lls-experimental` — built from upstream `latest`, may be unstable

A SHA-preserved tag is also pushed for every build for historic image preservation:

- `release-1.9-lls-0.4.3-<github_sha>`
- `release-1.9-lls-experimental-<github_sha>`

## versions.json

The [`versions.json`](versions.json) file is the single source of truth for mapping llama stack versions to upstream base image digests.

### Structure

```json
{
    "current_version": "0.4.3",
    "base_image": "quay.io/lightspeed-core/rag-content",
    "images": [
        {
            "llama_stack_version": "0.4.3",
            "digests": {
                "cpu": "sha256:314a616c0efc944e376f35a50c9d98f6aab53e68a0971a2195024474aee8209c",
                "gpu": "sha256:47885985ee3f534c1cec33b4e9c5d43b870ec791b963354cb3e9c48b36ead902"
            }
        },
        {
            "llama_stack_version": "latest",
            "digests": {
                "cpu": "sha256:...",
                "gpu": "sha256:..."
            }
        }
    ]
}
```

- `current_version` is the default llama stack version used by PR smoke tests (`.github/workflows/pr-tests.yml`).
- `base_image` is the upstream image repository prefix (e.g. `quay.io/lightspeed-core/rag-content`).
- `images` is an array of objects, each representing a supported llama stack version.
- `llama_stack_version` is the version string (e.g. `0.3.5`, `0.4.3`, `latest`).
- `digests` contains pinned image digests keyed by compute flavor (`cpu` / `gpu`). CI workflows always use `cpu`.
- The `latest` entry tracks the upstream `latest` tag and is considered experimental / potentially unstable.

### Adding a New Llama Stack Version

To add support for a new llama stack version:

1. Append a new object to the `images` array in `versions.json` with the version and pinned digests:

```json
{
    "llama_stack_version": "0.5.0",
    "digests": {
        "cpu": "sha256:abc123...",
        "gpu": "sha256:def456..."
    }
}
```

2. Run the **Generate and PR Vector Store** workflow with the new `llama_stack_version` and desired `version`. Merge the resulting PR in the vector-stores repo.
3. Run the **Build and Push RAG Container** workflow with `llama_stack_version` set to `0.5.0`.

## Release Strategy

- **Future release branches** (cut from `main`) carry their own copy of `versions.json` pinned to the llama stack versions validated for that release.
- **Existing release branches** (pre-refactor) retain the old workflow and are unaffected.
- **Cutting a new release**: branch from `main`, review `versions.json`, and lock it to only the versions that are known-good for that release (i.e., remove `latest` if desired). For the `Containerfile`, update `VECTOR_STORE_REF` to point to the appropriate release branch or tag in the vector-stores repo.
- **Rebuilding a historic image**: navigate to the release branch in GitHub and trigger the workflow. The workflow reads the branch's own `versions.json`, ensuring the correct upstream image digests are used.

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

This uses `Containerfile.local` which generates the vector DB during image build — no vector-stores repo dependency required. The `PLATFORM` variable defaults to `linux/amd64` but can be overridden (e.g. `PLATFORM=linux/arm64` on Apple Silicon).

## Verifying Vector Database

After building the container image, you can inspect and query the generated vector database to verify its contents.

### Building the Builder Stage

The `Containerfile.local` builder stage includes Python and all dependencies. To build just that stage for interactive verification:

```bash
podman build --platform linux/amd64 \
    --target lightspeed-core-rag-builder \
    -t rhdh-rag-builder \
    -f Containerfile.local .
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
