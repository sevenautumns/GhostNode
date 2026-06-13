# paperless-ghostnode

paperless-ghostnode is a paperless plugin for routing OCR through GhostNode instead of Tesseract.
The plugin registers a consumer which does a simple HTTP request to a number of GhostNodes.
Should all GhostNodes fail, the processing fails. 

A failed processing is not too bad. It keeps the failed files in the consume-folder where they can be "retried" (unfortunately, there is no retry button, but a restart of paperless re-scans the folder and "re-runs" them).

## Installation

Depending on your

### pip

plain `pip install` of paperless-ghostnode

```
pip install paperless-ghostnode
```

### Docker Compose

When using docker compose, we need to somehow give paperless access to the files of paperless-ghostnode.
One of the easiest one is to have an init-service, which installs the plugin into a shared volume via pip and then mount that volume into the paperless-worker.

```yaml
services:
  paperless-ghostnode-install:
    image: python:slim
    command: ["pip", "install", "--target", "/plugins", "paperless-ghostnode"]
    volumes:
      - paperless-ghostnode:/plugins

  paperless-worker:
    # ...
    depends_on:
      paperless-ghostnode-install:
        condition: service_completed_successfully
    volumes:
      - paperless-ghostnode:/plugins
    environment:
      PYTHONPATH: /plugins
      PAPERLESS_APPS: paperless_ghostnode
      PAPERLESS_GHOSTNODE_HOSTS: "192.168.x.x:8080"

volumes:
  paperless-ghostnode: {}
```

### Nix

When using nix, we can just load the plugin from PyPi, build it, and then directly attach it to the `PYTHONPATH` of the `paperless-task-queue` service.

```nix
let
  paperless-ghostnode = pkgs.python3Packages.buildPythonPackage {
    pname = "paperless-ghostnode";
    version = "0.1.0";
    src = pkgs.fetchPypi {
      pname = "paperless-ghostnode";
      version = "0.1.0";
      sha256 = "sha256-...";
    };
    format = "pyproject";
    nativeBuildInputs = [ pkgs.python3Packages.hatchling ];
  };
in {
  systemd.services.paperless-task-queue.environment = {
    PAPERLESS_APPS = "paperless_ghostnode";
    PYTHONPATH = "${paperless-ghostnode}/${pkgs.python3.sitePackages}";
    PAPERLESS_GHOSTNODE_HOSTS = "192.168.x.x:8080";
  };
}
```

## Configuration

- `PAPERLESS_APPS=paperless_ghostnode`: The plugin needs to be registered as an app
- `PAPERLESS_GHOSTNODE_HOSTS`: comma-separated list of `host:port` entries, tried in order. Should point to addresses which may host an active GhostNode app
- `PAPERLESS_GHOSTNODE_MODE`: `skip` (default), `force`, or `all`

## Why a parser and not a pre-consume script

Paperless supports [pre-consumption scripts](https://docs.paperless-ngx.com/advanced_usage/#pre-consume-script) that run before a document is processed.

Instead of the paperless-ghostnode plugin the pre-consumption-script can be used to OCR documents with GhostNode.
The main problem with that is that the pre-consumption-script is not considered "processing" by paperless.

I have not tested what happens, if the "reprocess" of a document is manually triggered from within paperless, when the pre-consumption-script is used. I would guess that either the pre-consumption-script is not rerun which would defeat the purpose of "reprocessing" or it is rerun, which would mean that the script is rerun on an already processed PDF as (we remember) the original is lost with a pre-consumption-script.
 
If despite these drawbacks you want to still use it, find the script below

### Pre-Consumption-Script

```bash
#!/usr/bin/env bash
set -euo pipefail

GHOSTNODE_URL="${GHOSTNODE_URL:-http://<ghostnode-ip>:8080}"

case "$DOCUMENT_WORKING_PATH" in
  *.pdf | *.PDF) ;;
  *)
    echo "ghostnode-ocr: not a PDF, skipping"
    exit 0
    ;;
esac

tmp=$(mktemp /tmp/ghostnode-ocr-XXXXXX.pdf)
trap 'rm -f "$tmp"' EXIT

echo "ghostnode-ocr: sending to GhostNode…"
if ! curl \
  --silent \
  --fail \
  --output "$tmp" \
  --max-time 300 \
  --request POST \
  --header "Content-Type: application/pdf" \
  --data-binary "@$DOCUMENT_WORKING_PATH" \
  "$GHOSTNODE_URL/api/v1/ocr?mode=skip"; then
  echo "ghostnode-ocr: GhostNode unreachable or returned error"
  exit 1
fi

cp "$tmp" "$DOCUMENT_WORKING_PATH"
echo "ghostnode-ocr: done"
```

Point Paperless at it via `PAPERLESS_PRE_CONSUME_SCRIPT` and set `PAPERLESS_OCR_SKIP_ARCHIVE_FILE=always` so Paperless doesn't re-OCR the result with Tesseract afterwards.
