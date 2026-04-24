import Foundation
import SwiftData

struct SettingsViewModel {
    let title: String
    private let ingestionService: SharedInboxIngestionService
    private let debugStateStore: SharedInboxDebugStateStore
    private let demoShowcaseService: any DemoShowcaseServicing

    init(environment: AppEnvironment = .live) {
        title = environment.shellService.appDisplayName
        ingestionService = SharedInboxIngestionService(environment: environment)
        debugStateStore = SharedInboxDebugStateStore()
        demoShowcaseService = environment.demoShowcaseService
    }

    @MainActor
    func ingestSharedQueue(into modelContext: ModelContext) -> SharedInboxIngestionReport {
        ingestionService.ingestPendingPayloads(into: modelContext)
    }

    func lastIngestionReport() -> SharedInboxIngestionReport? {
        debugStateStore.loadLastReport()
    }

    func lastIngestionFailureMessage() -> String? {
        guard let report = debugStateStore.loadLastReport(),
              let message = report.errorMessage else {
            return nil
        }
        return message
    }

    @MainActor
    func seedDemoData(into modelContext: ModelContext) -> DemoShowcaseReport {
        demoShowcaseService.seedDemoItems(in: modelContext)
    }

    @MainActor
    func clearDemoData(into modelContext: ModelContext) -> DemoShowcaseReport {
        demoShowcaseService.clearDemoItems(in: modelContext)
    }
}
