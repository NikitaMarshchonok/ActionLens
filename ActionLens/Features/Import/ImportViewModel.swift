import Foundation
import os
import SwiftData

enum ImportOperationResult {
    case success(title: String)
    case failure(message: String)
}

struct ImportViewModel {
    private static let logger = Logger(subsystem: "ActionLens", category: "Import")

    let title: String
    private let importService: any ImportServicing
    private let ocrService: any OCRServicing
    private let entityExtractionService: any EntityExtractionServicing
    private let itemClassificationService: any ItemClassificationServicing

    init(environment: AppEnvironment = .live) {
        title = environment.shellService.appDisplayName
        importService = environment.importService
        ocrService = environment.ocrService
        entityExtractionService = environment.entityExtractionService
        itemClassificationService = environment.itemClassificationService
    }

    func addPhotoImportedItem(photoData: Data, in modelContext: ModelContext) async -> ImportOperationResult {
        let extractedText = await ocrService.extractText(from: photoData)
        let entities = extractedText.map { entityExtractionService.extractEntities(from: $0) } ?? ExtractedEntities()
        let itemType = itemClassificationService.classify(
            title: "Imported Photo",
            sourceType: "Photos",
            extractedText: extractedText,
            entities: entities
        )

        let item = importService.makeImportedItem(
            title: "Imported Photo",
            sourceType: "Photos",
            extractedText: extractedText,
            itemTypeRaw: itemType.rawValue
        )
        modelContext.insert(item)
        do {
            try modelContext.save()
            return .success(title: item.title)
        } catch {
            modelContext.delete(item)
            Self.logger.error("Failed to save imported photo item: \(error.localizedDescription, privacy: .public)")
            return .failure(message: "Could not save imported photo. Please try again.")
        }
    }

    func addFileImportedItem(from url: URL, in modelContext: ModelContext) -> ImportOperationResult {
        let baseName = url.deletingPathExtension().lastPathComponent
        let title = baseName.isEmpty ? "Imported File" : baseName
        let itemType = itemClassificationService.classify(
            title: title,
            sourceType: "Files",
            extractedText: nil,
            entities: ExtractedEntities()
        )

        let item = importService.makeImportedItem(
            title: title,
            sourceType: "Files",
            extractedText: nil,
            itemTypeRaw: itemType.rawValue
        )
        modelContext.insert(item)
        do {
            try modelContext.save()
            return .success(title: item.title)
        } catch {
            modelContext.delete(item)
            Self.logger.error("Failed to save imported file item: \(error.localizedDescription, privacy: .public)")
            return .failure(message: "Could not save imported file. Please try again.")
        }
    }
}
