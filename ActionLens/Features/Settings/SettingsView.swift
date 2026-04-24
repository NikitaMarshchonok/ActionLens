import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(OnboardingState.shouldPresentKey) private var shouldPresentOnboarding = false
    @State private var debugReportText: String?
    @State private var demoReportText: String?

    private let viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    Text("\(viewModel.title) Settings")
                        .foregroundStyle(.secondary)

                    Button("Show Onboarding Again") {
                        shouldPresentOnboarding = true
                    }
                }

                if let ingestionFailureMessage = viewModel.lastIngestionFailureMessage() {
                    Section("Import Status") {
                        Text("Some shared imports could not be saved. \(ingestionFailureMessage)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

#if DEBUG
                Section("Developer") {
                    Button("Ingest Shared Queue Now") {
                        let report = viewModel.ingestSharedQueue(into: modelContext)
                        debugReportText = report.summaryText
                    }

                    Button("Seed Demo Showcase Data") {
                        let report = viewModel.seedDemoData(into: modelContext)
                        demoReportText = report.message
                    }

                    Button("Clear Demo Showcase Data", role: .destructive) {
                        let report = viewModel.clearDemoData(into: modelContext)
                        demoReportText = report.message
                    }
                }

                Section("Share Ingestion") {
                    if let debugReportText {
                        Text(debugReportText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else if let report = viewModel.lastIngestionReport() {
                        Text("\(report.summaryText)\n\(report.createdAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No ingestion report yet.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Demo Showcase") {
                    if let demoReportText {
                        Text(demoReportText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Use Developer actions to seed or clear demo items.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
#endif
            }
            .navigationTitle("Settings")
        }
    }
}
