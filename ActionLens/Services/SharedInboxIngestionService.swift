import Foundation
import SwiftData

struct SharedInboxIngestionService {
    private let sharedInboxStore: SharedInboxStore
    private let importService: any ImportServicing
    private let entityExtractionService: any EntityExtractionServicing
    private let itemClassificationService: any ItemClassificationServicing

    init(
        environment: AppEnvironment = .live,
        sharedInboxStore: SharedInboxStore = SharedInboxStore()
    ) {
        self.sharedInboxStore = sharedInboxStore
        importService = environment.importService
        entityExtractionService = environment.entityExtractionService
        itemClassificationService = environment.itemClassificationService
    }

    @MainActor
    func ingestPendingPayloads(into modelContext: ModelContext) {
        let payloads = sharedInboxStore.dequeueAll()
        guard payloads.isEmpty == false else { return }

        for payload in payloads {
            let descriptor = descriptor(for: payload)
            let entities = descriptor.extractedText.map {
                entityExtractionService.extractEntities(from: $0)
            } ?? ExtractedEntities()

            let itemType = itemClassificationService.classify(
                title: descriptor.title,
                sourceType: descriptor.sourceType,
                extractedText: descriptor.extractedText,
                entities: entities
            )

            let item = importService.makeImportedItem(
                title: descriptor.title,
                sourceType: descriptor.sourceType,
                extractedText: descriptor.extractedText,
                itemTypeRaw: itemType.rawValue
            )
            modelContext.insert(item)
        }

        try? modelContext.save()
    }

    private func descriptor(for payload: SharedInboxPayload) -> (title: String, sourceType: String, extractedText: String?) {
        switch payload.type {
        case .text:
            let rawText = payload.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let title = rawText.isEmpty ? "Shared Text" : String(rawText.prefix(80))
            return (title, "Share Text", rawText.isEmpty ? nil : rawText)
        case .url:
            let urlText = payload.urlString ?? ""
            let title = URL(string: urlText)?.host ?? "Shared URL"
            return (title, "Share URL", urlText.isEmpty ? nil : urlText)
        case .image:
            let fileName = payload.fileName ?? "Shared Image"
            let title = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
            return (title.isEmpty ? "Shared Image" : title, "Share Image", nil)
        case .file:
            let fileName = payload.fileName ?? "Shared File"
            let title = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
            return (title.isEmpty ? "Shared File" : title, "Share File", nil)
        }
    }
}
