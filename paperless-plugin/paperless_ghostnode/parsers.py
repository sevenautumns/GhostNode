import os
import urllib.parse
import urllib.request
from pathlib import Path

from documents.parsers import ParseError
from paperless_tesseract.parsers import RasterisedDocumentParser

DEFAULT_MODE = "skip"


class GhostNodeDocumentParser(RasterisedDocumentParser):
    """Routes OCR through GhostNode instead of Tesseract."""

    logging_name = "paperless.parsing.ghostnode"

    def parse(self, document_path, mime_type, file_name=None):
        hosts = [
            host.strip()
            for host in os.environ.get("PAPERLESS_GHOSTNODE_HOSTS", "").split(",")
            if host.strip()
        ]
        if not hosts:
            raise ParseError(
                "PAPERLESS_GHOSTNODE_HOSTS is unset or empty, set it to a comma-separated list of host:port entries.",
            )
        mode = os.environ.get("PAPERLESS_GHOSTNODE_MODE", DEFAULT_MODE)

        archive_path = Path(self.tempdir) / "archive.pdf"
        data = Path(document_path).read_bytes()
        query = urllib.parse.urlencode({"mode": mode})

        last_error = None
        for host in hosts:
            url = f"http://{host}/api/v1/ocr?{query}"
            try:
                self.log.debug(f"Sending document to GhostNode at {host} (mode={mode})")
                request = urllib.request.Request(
                    url,
                    data=data,
                    headers={"Content-Type": mime_type},
                    method="POST",
                )
                # urlopen raises HTTPError on non-2xx
                with urllib.request.urlopen(request, timeout=300) as response:
                    archive_path.write_bytes(response.read())
                self.archive_path = archive_path
                self.text = self.extract_text(None, archive_path)
                self.log.debug(f"GhostNode OCR done via {host}")
                return
            except Exception as e:
                last_error = e
                self.log.warning(f"GhostNode host {host} failed: {e}")

        raise ParseError(
            f"GhostNode OCR failed on all hosts ({', '.join(hosts)}): {last_error}",
        )
