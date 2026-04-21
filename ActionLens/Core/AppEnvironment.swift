struct AppEnvironment {
    let shellService: any AppShellServicing
    let importService: any ImportServicing
    let ocrService: any OCRServicing
    let entityExtractionService: any EntityExtractionServicing
    let itemClassificationService: any ItemClassificationServicing
    let urgencyGroupingService: any InboxUrgencyGroupingServicing

    static let live = AppEnvironment(
        shellService: AppShellService(),
        importService: ImportService(),
        ocrService: ImageOCRService(),
        entityExtractionService: LocalEntityExtractionService(),
        itemClassificationService: LocalItemClassificationService(),
        urgencyGroupingService: LocalInboxUrgencyGroupingService()
    )
}
