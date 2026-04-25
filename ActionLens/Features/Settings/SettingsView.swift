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
                    Text("Manage onboarding and app status.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        shouldPresentOnboarding = true
                    } label: {
                        Label("Show Onboarding Again", systemImage: "sparkles")
                    }
                }

                if let ingestionFailureMessage = viewModel.lastIngestionFailureMessage() {
                    Section("Import Status") {
                        Label("Some shared imports could not be saved.", systemImage: "exclamationmark.triangle")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red)

                        Text(ingestionFailureMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

#if DEBUG
                Section("Developer (Debug)") {
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
                } footer: {
                    Text("Debug tools are for development builds only.")
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
            .listSectionSpacing(20)
            .navigationTitle("Settings")
        }
    }
}
