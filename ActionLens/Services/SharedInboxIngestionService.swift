import Foundation
import os
import SwiftData

struct SharedInboxIngestionReport: Codable {
    let processedCount: Int
    let createdCount: Int
    let skippedCount: Int
    let createdAt: Date

    var summaryText: String {
        "Processed: \(processedCount), Created: \(createdCount), Skipped: \(skippedCount)"
    }
}

struct SharedInboxIngestionService {
    private static let logger = Logger(subsystem: "ActionLens", category: "SharedInboxIngestion")
    private static let processedPayloadIDsKey = "sharedInbox.processedPayloadIDs.v1"
    private static let maxProcessedIDs = 300

    private let sharedInboxStore: SharedInboxStore
    private let importService: any ImportServicing
    private let entityExtractionService: any EntityExtractionServicing
    private let itemClassificationService: any ItemClassificationServicing
    private let debugStateStore: SharedInboxDebugStateStore

    init(
        environment: AppEnvironment = .live,
        sharedInboxStore: SharedInboxStore = SharedInboxStore(),
        debugStateStore: SharedInboxDebugStateStore = SharedInboxDebugStateStore()
    ) {
        self.sharedInboxStore = sharedInboxStore
        self.debugStateStore = debugStateStore
        importService = environment.importService
        entityExtractionService = environment.entityExtractionService
        itemClassificationService = environment.itemClassificationService
    }

    @discardableResult
    @MainActor
    func ingestPendingPayloads(into modelContext: ModelContext) -> SharedInboxIngestionReport {
        let payloads = sharedInboxStore.dequeueAll()
        guard payloads.isEmpty == false else {
            let report = SharedInboxIngestionReport(
                processedCount: 0,
                createdCount: 0,
                skippedCount: 0,
                createdAt: .now
            )
            debugStateStore.saveLastReport(report)
            return report
        }

        var processedIDs = loadProcessedPayloadIDs()
        var createdCount = 0
        var skippedCount = 0

        for payload in payloads {
            if processedIDs.contains(payload.id.uuidString) {
                skippedCount += 1
                continue
            }

            let descriptor = descriptor(for: payload)
            guard descriptor.isValid else {
                skippedCount += 1
                processedIDs.insert(payload.id.uuidString)
                continue
            }

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
            createdCount += 1
            processedIDs.insert(payload.id.uuidString)
        }

        try? modelContext.save()

        saveProcessedPayloadIDs(processedIDs)

        let report = SharedInboxIngestionReport(
            processedCount: payloads.count,
            createdCount: createdCount,
            skippedCount: skippedCount
                + max(0, payloads.count - createdCount - skippedCount),
            createdAt: .now
        )
        debugStateStore.saveLastReport(report)
        Self.logger.log("Share ingestion finished. \(report.summaryText)")
        return report
    }

    private func descriptor(for payload: SharedInboxPayload) -> (title: String, sourceType: String, extractedText: String?, isValid: Bool) {
        switch payload.type {
        case .text:
            let rawText = payload.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let title = rawText.isEmpty ? "Shared Text" : String(rawText.prefix(80))
            return (title, "Share Text", rawText.isEmpty ? nil : rawText, true)
        case .url:
            let urlText = payload.urlString ?? ""
            let title = URL(string: urlText)?.host ?? "Shared URL"
            return (title, "Share URL", urlText.isEmpty ? nil : urlText, true)
        case .image:
            let fileName = payload.fileName ?? "Shared Image"
            let title = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
            return (title.isEmpty ? "Shared Image" : title, "Share Image", nil, true)
        case .file:
            let fileName = payload.fileName ?? "Shared File"
            let title = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
            let extractedText = readTextFromSharedFile(relativeFilePath: payload.relativeFilePath)
            return (title.isEmpty ? "Shared File" : title, "Share File", extractedText, true)
        }
    }

    private func readTextFromSharedFile(relativeFilePath: String?) -> String? {
        guard let relativeFilePath,
              let directoryURL = sharedInboxStore.sharedFilesDirectoryURL() else {
            return nil
        }

        let fileURL = directoryURL.appendingPathComponent(relativeFilePath)
        let textExtensions: Set<String> = ["txt", "md", "rtf", "csv", "json", "log"]
        let ext = fileURL.pathExtension.lowercased()
        guard textExtensions.contains(ext) else { return nil }

        return try? String(contentsOf: fileURL, encoding: .utf8)
    }

    private func loadProcessedPayloadIDs() -> Set<String> {
        let values = UserDefaults.standard.stringArray(forKey: Self.processedPayloadIDsKey) ?? []
        return Set(values)
    }

    private func saveProcessedPayloadIDs(_ ids: Set<String>) {
        let limited = Array(ids.prefix(Self.maxProcessedIDs))
        UserDefaults.standard.set(limited, forKey: Self.processedPayloadIDsKey)
    }
}
