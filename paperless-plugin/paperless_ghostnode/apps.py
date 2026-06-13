from django.apps import AppConfig


class GhostNodeConfig(AppConfig):
    name = "paperless_ghostnode"

    def ready(self):
        from documents.signals import document_consumer_declaration

        from paperless_ghostnode.signals import ghostnode_consumer_declaration

        document_consumer_declaration.connect(ghostnode_consumer_declaration)

        AppConfig.ready(self)
