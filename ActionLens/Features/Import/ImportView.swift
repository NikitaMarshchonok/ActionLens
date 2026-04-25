import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import os

struct ImportView: View {
    private static let logger = Logger(subsystem: "ActionLens", category: "ImportView")
    @Environment(\.modelContext) private var modelContext
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isShowingFileImporter = false
    @State private var lastImportMessage: String?
    @State private var isImportingPhoto = false

    private let viewModel = ImportViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section("Quick Import") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("From Photos", systemImage: "photo.on.rectangle")
                    }

                    Button {
                        isShowingFileImporter = true
                    } label: {
                        Label("From Files", systemImage: "doc.badge.plus")
                    }
                } footer: {
                    Text("Import one item at a time. New items appear in Inbox.")
                }

                Section("What happens next") {
                    Text("Imported content is analyzed and action suggestions appear when available.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if isImportingPhoto {
                    Section {
                        ProgressView("Extracting text from selected image...")
                    }
                }

                if lastImportMessage == nil, isImportingPhoto == false {
                    Section("Status") {
                        Label("Ready to import", systemImage: "checkmark.circle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if let lastImportMessage {
                    Section("Last Import") {
                        Label(lastImportMessage, systemImage: statusIcon(for: lastImportMessage))
                            .font(.subheadline)
                            .foregroundStyle(statusColor(for: lastImportMessage))
                    }
                }
            }
            .navigationTitle("Import")
            .onChange(of: selectedPhotoItem) { _, newSelection in
                guard newSelection != nil else { return }
                Task {
                    isImportingPhoto = true

                    guard let newSelection else {
                        lastImportMessage = "Photo import failed."
                        selectedPhotoItem = nil
                        isImportingPhoto = false
                        return
                    }

                    let photoData: Data
                    do {
                        guard let loadedData = try await newSelection.loadTransferable(type: Data.self) else {
                            lastImportMessage = "Could not read selected photo."
                            selectedPhotoItem = nil
                            isImportingPhoto = false
                            return
                        }
                        photoData = loadedData
                    } catch {
                        Self.logger.error("Photo transfer failed: \(error.localizedDescription, privacy: .public)")
                        lastImportMessage = "Photo import failed."
                        selectedPhotoItem = nil
                        isImportingPhoto = false
                        return
                    }

                    switch await viewModel.addPhotoImportedItem(photoData: photoData, in: modelContext) {
                    case .success(let title):
                        lastImportMessage = "Added \"\(title)\" from Photos."
                    case .successNoText(let title):
                        lastImportMessage = "Added \"\(title)\" from Photos. No text was detected."
                    case .failure(let message):
                        lastImportMessage = message
                    }
                    selectedPhotoItem = nil
                    isImportingPhoto = false
                }
            }
            .fileImporter(
                isPresented: $isShowingFileImporter,
                allowedContentTypes: [.image, .pdf, .item],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else {
                        lastImportMessage = "No file selected."
                        return
                    }
                    switch viewModel.addFileImportedItem(from: url, in: modelContext) {
                    case .success(let title):
                        lastImportMessage = "Added \"\(title)\" from Files."
                    case .successNoText:
                        lastImportMessage = "Added file from Files."
                    case .failure(let message):
                        lastImportMessage = message
                    }
                case .failure:
                    lastImportMessage = "Import canceled."
                }
            }
        }
    }

    private func statusIcon(for message: String) -> String {
        let normalized = message.lowercased()
        if normalized.contains("failed")
            || normalized.contains("could not")
            || normalized.contains("canceled")
            || normalized.contains("no file selected") {
            return "exclamationmark.triangle"
        }
        return "checkmark.circle"
    }

    private func statusColor(for message: String) -> Color {
        let normalized = message.lowercased()
        if normalized.contains("failed")
            || normalized.contains("could not")
            || normalized.contains("canceled")
            || normalized.contains("no file selected") {
            return .red
        }
        return .secondary
    }
}
