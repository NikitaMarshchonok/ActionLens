import SwiftData
import SwiftUI

@main
struct ActionLensApp: App {
    @Environment(\.scenePhase) private var scenePhase

    private let sharedInboxIngestionService = SharedInboxIngestionService()

    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([InboxItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .task {
                    await ingestSharedPayloads()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task {
                        await ingestSharedPayloads()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }

    @MainActor
    private func ingestSharedPayloads() async {
        sharedInboxIngestionService.ingestPendingPayloads(into: sharedModelContainer.mainContext)
    }
}
