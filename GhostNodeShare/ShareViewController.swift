import GhostNodeShared
import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        Task { await run() }
    }

    private func run() async {
        let providers = (extensionContext?.inputItems ?? [])
            .compactMap { $0 as? NSExtensionItem }
            .flatMap { $0.attachments ?? [] }

        var filenames: [String] = []
        for provider in providers {
            if let name = await deposit(provider) {
                filenames.append(name)
            }
        }
        await finish(filenames: filenames)
    }

    private func deposit(_ provider: NSItemProvider) async -> String? {
        guard let (typeID, ext) = matchType(provider) else { return nil }
        guard let data = try? await provider.loadData(forTypeIdentifier: typeID) else {
            return nil
        }
        return try? SharedInbox.deposit(data, pathExtension: ext)
    }

    private func matchType(_ provider: NSItemProvider) -> (String, String)? {
        let types = provider.registeredTypeIdentifiers.compactMap(UTType.init)
        if let pdf = types.first(where: { $0.conforms(to: .pdf) }) {
            return (pdf.identifier, pdf.preferredFilenameExtension ?? "pdf")
        }
        if let img = types.first(where: { $0.conforms(to: .image) }) {
            return (img.identifier, img.preferredFilenameExtension ?? "img")
        }
        return nil
    }

    @MainActor
    private func finish(filenames: [String]) async {
        guard !filenames.isEmpty,
              let url = SharedInbox.handoffURL(filenames: filenames)
        else {
            extensionContext?.completeRequest(returningItems: nil)
            return
        }
        _ = await extensionContext?.open(url)
        extensionContext?.completeRequest(returningItems: nil)
    }
}
