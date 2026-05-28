<p align="center">
  <img src="GhostNode/Assets.xcassets/GhostIcon.imageset/Ghost.svg" alt="Logo" width="200">
</p>

# GhostNode

GhostNode is an iOS/macOS App for applying Optical Character Recognition (OCR) to images and PDF-documents.
It produces a PDF-document where the detected text is overlayed as invisible but selectable text.

## Technology

Based on the used operating system, GhostNode utilizes either `RecognizeDocumentsRequest` or `VNRecognizeTextRequest`.
- `RecognizeDocumentsRequest` is Apples new OCR API introduced with iOS26/macOS26
- `VNRecognizeTextRequest` is the old OCR API used before that

The overlayed PDF is created using my [GhostLayer](https://github.com/sevenautumns/GhostLayer), another library from me, which does basically what [Tesseract](https://github.com/tesseract-ocr/tesseract) is doing for their PDF overlaying.

## Why

I really like [Paperless-ngx](https://github.com/paperless-ngx/paperless-ngx), but I dislike the quality of [Tesseracts](https://github.com/tesseract-ocr/tesseract) OCR, so I build this app, so my old iPhone can be used for OCR instead. Because of that this app also features a REST-API, so that in Paperless, everything can be sent to my iPhone for processing instead.

## Paperless-ngx Integration

Paperless supports [pre-consumption scripts](https://docs.paperless-ngx.com/advanced_usage/#pre-consume-script) that run before a document is processed. This is the hook I use to pipe documents through GhostNode.

The script POSTs the document to GhostNode and replaces the working copy with the OCR'd result. If GhostNode is unreachable, it exits with a non-zero code, so the document stays in the consume folder and can be retried later.

```bash
#!/usr/bin/env bash
set -euo pipefail

GHOSTNODE_URL="${GHOSTNODE_URL:-http://<your-iphone-ip>:8080}"

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

### API

`POST /api/v1/ocr` — accepts a PDF or image as the request body, returns an OCR'd PDF.

The `mode` query parameter controls how existing text layers are handled:
- `skip` — only OCR pages that have no existing text (default)
- `force` — OCR every page regardless
- `all` — OCR every page but keep existing text layers

The server runs on port `8080` by default and is reachable as long as the app is in the foreground or background (it stops when the app is terminated).

## Privacy

The OCR is performed entirely on your device and nothing is collected or send elsewhere.
You can get more information about privacy in the [PRIVACY.md](PRIVACY.md).

## Licence

- Code: Apache Licence 2.0
- Icon/Graphics: Copyright © 2026 Sina Friedrich. All rights reserved.
