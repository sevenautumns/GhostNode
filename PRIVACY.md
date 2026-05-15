# Privacy Policy for GhostNode

_Last updated: 2026-05-20_

GhostNode is an iOS and macOS application that performs optical character recognition (OCR) on images and PDF documents. This policy explains what data GhostNode does — and does not — handle.

## Summary

GhostNode does not collect, store, transmit, or share any personal information. All processing happens entirely on your device.

## Data we do not collect

- No analytics, telemetry, or usage statistics
- No crash reports
- No advertising identifiers or other tracking
- No user accounts or sign-ups
- No third-party SDKs that process your data

## Data the app processes on your device

OCR is performed entirely on-device using Apple's Vision framework. Images and PDF documents you import:

- Are read only when you explicitly choose them
- Are processed locally on your device
- Are not transmitted to GhostNode's developer or any third party

## Permissions

GhostNode requests the following system permissions only when relevant to the feature you use:

- **Camera** — to scan paper documents directly. Frames are processed on-device and discarded after the document is captured.
- **Photo Library** — to import photos you select. GhostNode does not access photos you do not explicitly pick.
- **Local Network** — to expose an optional local OCR HTTP server to other devices on your Wi-Fi network. The server is bound to the local network only and is not reachable from the public internet.

## Local OCR server

GhostNode includes an optional feature that exposes an HTTP endpoint on your local Wi-Fi network so other devices (for example a laptop) can submit images or PDFs for OCR. When you use this feature:

- The server runs only while the app is open
- Requests, request bodies, and OCR results stay on your local network
- No data is forwarded to GhostNode's developer or any external service

## Changes to this policy

If this policy changes in a meaningful way, the updated version will be published in this repository with a new "Last updated" date.

## Contact

Questions about this policy can be filed as an issue at <https://github.com/sevenautumns/GhostNode/issues>.
