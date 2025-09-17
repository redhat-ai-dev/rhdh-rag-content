# RHDH RAG CONTENT

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