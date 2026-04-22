import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var debugReportText: String?

    private let viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    Text("\(viewModel.title) Settings")
                        .foregroundStyle(.secondary)
                }

#if DEBUG
                Section("Developer") {
                    Button("Ingest Shared Queue Now") {
                        let report = viewModel.ingestSharedQueue(into: modelContext)
                        debugReportText = report.summaryText
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
#endif
            }
            .navigationTitle("Settings")
        }
    }
}
