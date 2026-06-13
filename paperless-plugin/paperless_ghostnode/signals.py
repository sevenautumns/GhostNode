def get_parser(*args, **kwargs):
    from paperless_ghostnode.parsers import GhostNodeDocumentParser

    return GhostNodeDocumentParser(*args, **kwargs)


def ghostnode_consumer_declaration(sender, **kwargs):
    # weight 1 > Tesseract's 0, so GhostNode wins for these types
    return {
        "parser": get_parser,
        "weight": 1,
        "mime_types": {
            "application/pdf": ".pdf",
            "image/jpeg": ".jpg",
            "image/png": ".png",
            "image/tiff": ".tif",
            "image/gif": ".gif",
            "image/bmp": ".bmp",
            "image/webp": ".webp",
            "image/heic": ".heic",
        },
    }
