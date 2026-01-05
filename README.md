# RHDH RAG CONTENT

[![Apache2.0 License](https://img.shields.io/badge/license-Apache2.0-brightgreen.svg)](LICENSE)

> [!NOTE]
> The `main` branch host the RHDH RAG logic compatible with lightspeed-core's [LCS](https://github.com/lightspeed-core/lightspeed-stack) and [rag-content](https://github.com/lightspeed-core/rag-content).
> 
> The `road-core-rag-content` branch host the RHDH RAG logic compatible with road-core's [RCS](https://github.com/road-core/service).

# Usage

To install the project dependencies:
```
uv sync
```

Activate the venv, and you should be able to execute the python scripts

# Image Registry

To build a container image, run
```
make build-image-rhdh-example
```

The quay image is located in [redhat-ai-dev/rag-content](https://quay.io/repository/redhat-ai-dev/rag-content?tab=tags).

# Verifying Vector Database

After building the container image, you can inspect and query the generated vector database to verify its contents.

## Building the Builder Stage

The final container image is minimal and only contains the vector database files. To run verification scripts, build the builder stage which includes Python and all dependencies:

```bash
podman build --platform linux/arm64 \
    --target lightspeed-core-rag-builder \
    -t rhdh-rag-builder \
    -f Containerfile.rhdh_lightspeed \
    --build-arg FLAVOR=cpu .
```

Then start an interactive shell:

```bash
podman run --rm -it rhdh-rag-builder /bin/bash
```

## Inspecting the Vector Database

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

### Options

| Flag | Description |
|------|-------------|
| `-p, --db-path` | Path to the vector database directory (required) |
| `--sample N` | Show N sample chunks with readable content |
| `--list-chunks` | Output all chunks |
| `--json` | Output in JSON format |

## Querying the Vector Database

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

### Options

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
