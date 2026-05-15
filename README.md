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

I'll probably add some code snippets for Paperless integration, when I integrated it myself.

## Privacy

The OCR is performed entirely on your device and nothing is collected or send elsewhere.
You can get more information about privacy in the [PRIVACY.md](PRIVACY.md).

## Licence

- Code: Apache Licence 2.0
- Icon/Graphics: Copyright © 2026 Sina Friedrich. All rights reserved.
