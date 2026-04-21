import SwiftData

struct ItemTypeBackfillService {
    private let entityExtractionService: any EntityExtractionServicing
    private let itemClassificationService: any ItemClassificationServicing

    init(environment: AppEnvironment = .live) {
        entityExtractionService = environment.entityExtractionService
        itemClassificationService = environment.itemClassificationService
    }

    @MainActor
    func refreshItemTypesIfNeeded(in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<InboxItem>()
        guard let items = try? modelContext.fetch(descriptor), items.isEmpty == false else {
            return
        }

        var didChange = false

        for item in items {
            let entities = item.extractedText.map {
                entityExtractionService.extractEntities(from: $0)
            } ?? ExtractedEntities()

            let computedType = itemClassificationService.classify(
                title: item.title,
                sourceType: item.sourceType,
                extractedText: item.extractedText,
                entities: entities
            )

            if item.itemTypeRaw != computedType.rawValue {
                item.itemTypeRaw = computedType.rawValue
                didChange = true
            }
        }

        if didChange {
            try? modelContext.save()
        }
    }
}
