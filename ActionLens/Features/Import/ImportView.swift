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
                Section("Import Sources") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Import Image from Photos", systemImage: "photo.on.rectangle")
                    }

                    Button {
                        isShowingFileImporter = true
                    } label: {
                        Label("Import File", systemImage: "doc.badge.plus")
                    }
                }

                Section("Notes") {
                    Text("Imported items are added to Inbox and analyzed for text/actions when available.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if isImportingPhoto {
                    Section {
                        ProgressView("Extracting text from selected image...")
                    }
                }

                if let lastImportMessage {
                    Section("Last Import") {
                        Text(lastImportMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
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
                    guard let url = urls.first else { return }
                    switch viewModel.addFileImportedItem(from: url, in: modelContext) {
                    case .success(let title):
                        lastImportMessage = "Added \"\(title)\" from Files."
                    case .failure(let message):
                        lastImportMessage = message
                    }
                case .failure:
                    lastImportMessage = "Import canceled or failed."
                }
            }
        }
    }
}
