import Social
import UniformTypeIdentifiers
import os

final class ShareViewController: SLComposeServiceViewController {
    private let sharedStore = ExtensionSharedInboxStore()
    private let logger = Logger(subsystem: "ActionLens", category: "ShareExtension")

    override func isContentValid() -> Bool {
        true
    }

    override func didSelectPost() {
        Task {
            if await handleInputItems() {
                extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            } else {
                logger.error("Share extension could not import shared content.")
                let error = NSError(
                    domain: "ActionLensShareExtension",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Could not import this shared item."]
                )
                extensionContext?.cancelRequest(withError: error)
            }
        }
    }

    override func configurationItems() -> [Any]! {
        []
    }

    private func handleInputItems() async -> Bool {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            return false
        }

        for extensionItem in extensionItems {
            guard let attachments = extensionItem.attachments else { continue }

            for itemProvider in attachments {
                if let payload = await payloadFromProvider(itemProvider) {
                    sharedStore.enqueue(payload)
                    return true
                }
            }
        }

        return false
    }

    private func payloadFromProvider(_ provider: NSItemProvider) async -> ExtensionSharedInboxPayload? {
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
           let sharedURL = await loadURL(from: provider) {
            return ExtensionSharedInboxPayload(
                type: .url,
                urlString: sharedURL.absoluteString
            )
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
           let sharedText = await loadText(from: provider) {
            return ExtensionSharedInboxPayload(
                type: .text,
                text: sharedText
            )
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier),
           let copiedImage = await copyFileRepresentation(from: provider, typeIdentifier: UTType.image.identifier) {
            return ExtensionSharedInboxPayload(
                type: .image,
                fileName: copiedImage.lastPathComponent,
                relativeFilePath: copiedImage.lastPathComponent
            )
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.item.identifier),
           let copiedFile = await copyFileRepresentation(from: provider, typeIdentifier: UTType.item.identifier) {
            return ExtensionSharedInboxPayload(
                type: .file,
                fileName: copiedFile.lastPathComponent,
                relativeFilePath: copiedFile.lastPathComponent
            )
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.data.identifier),
           let copiedFile = await copyFileRepresentation(from: provider, typeIdentifier: UTType.data.identifier) {
            return ExtensionSharedInboxPayload(
                type: .file,
                fileName: copiedFile.lastPathComponent,
                relativeFilePath: copiedFile.lastPathComponent
            )
        }

        return nil
    }

    private func loadURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                if let url = item as? URL {
                    continuation.resume(returning: url)
                } else if let data = item as? Data,
                          let text = String(data: data, encoding: .utf8),
                          let url = URL(string: text) {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func loadText(from provider: NSItemProvider) async -> String? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                if let text = item as? String {
                    continuation.resume(returning: text)
                } else if let data = item as? Data,
                          let text = String(data: data, encoding: .utf8) {
                    continuation.resume(returning: text)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func copyFileRepresentation(from provider: NSItemProvider, typeIdentifier: String) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { sourceURL, _ in
                guard let sourceURL,
                      let directoryURL = self.sharedStore.sharedFilesDirectoryURL() else {
                    continuation.resume(returning: nil)
                    return
                }

                let destinationURL = directoryURL.appendingPathComponent("\(UUID().uuidString)-\(sourceURL.lastPathComponent)")
                do {
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                    continuation.resume(returning: destinationURL)
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
