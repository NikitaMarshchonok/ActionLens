import Foundation
import SwiftData

struct SettingsViewModel {
    let title: String
    private let ingestionService: SharedInboxIngestionService
    private let debugStateStore: SharedInboxDebugStateStore

    init(environment: AppEnvironment = .live) {
        title = environment.shellService.appDisplayName
        ingestionService = SharedInboxIngestionService(environment: environment)
        debugStateStore = SharedInboxDebugStateStore()
    }

    @MainActor
    func ingestSharedQueue(into modelContext: ModelContext) -> SharedInboxIngestionReport {
        ingestionService.ingestPendingPayloads(into: modelContext)
    }

    func lastIngestionReport() -> SharedInboxIngestionReport? {
        debugStateStore.loadLastReport()
    }
}
