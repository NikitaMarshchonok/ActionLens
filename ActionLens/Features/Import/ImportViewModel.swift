import Foundation
import SwiftData

struct ImportViewModel {
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

    func addPhotoImportedItem(photoData: Data, in modelContext: ModelContext) async -> String {
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
        try? modelContext.save()
        return item.title
    }

    func addFileImportedItem(from url: URL, in modelContext: ModelContext) -> String {
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
        try? modelContext.save()
        return item.title
    }
}
