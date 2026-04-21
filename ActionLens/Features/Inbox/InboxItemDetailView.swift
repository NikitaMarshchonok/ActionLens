import SwiftData
import SwiftUI

struct InboxItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Bindable private var item: InboxItem
    @State private var lastActionMessage: String?

    private let viewModel = InboxItemDetailViewModel()

    init(item: InboxItem) {
        self.item = item
    }

    var body: some View {
        let detectedEntities = viewModel.extractedEntities(for: item)
        let suggestedActions = viewModel.suggestedActions(for: item, entities: detectedEntities)

        List {
            Section("Item Details") {
                LabeledContent("Title", value: item.title)
                LabeledContent("Type", value: viewModel.itemTypeText(for: item))
                LabeledContent("Source Type", value: item.sourceType)
                LabeledContent("Status", value: item.status)
                LabeledContent("Created At", value: viewModel.createdAtText(for: item))
            }

            Section("Extracted Text") {
                if let extractedText = item.extractedText, extractedText.isEmpty == false {
                    Text(extractedText)
                        .font(.body)
                        .textSelection(.enabled)
                } else {
                    Text("No extracted text found.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Detected Values") {
                if detectedEntities.isEmpty {
                    Text("No values detected.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    if let value = detectedEntities.date {
                        LabeledContent("Date", value: value)
                    }
                    if let value = detectedEntities.time {
                        LabeledContent("Time", value: value)
                    }
                    if let value = detectedEntities.amount {
                        LabeledContent("Amount", value: value)
                    }
                    if let value = detectedEntities.email {
                        LabeledContent("Email", value: value)
                    }
                    if let value = detectedEntities.phoneNumber {
                        LabeledContent("Phone", value: value)
                    }
                    if let value = detectedEntities.url {
                        LabeledContent("URL", value: value)
                    }
                }
            }

            Section("Suggested Actions") {
                if suggestedActions.isEmpty {
                    Text("No suggested actions available.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(suggestedActions, id: \.id) { action in
                        Button {
                            Task {
                                lastActionMessage = await viewModel.performSuggestedAction(
                                    action,
                                    for: item,
                                    entities: detectedEntities,
                                    in: modelContext,
                                    openURLHandler: { url in
                                        openURL(url)
                                    }
                                )
                            }
                        } label: {
                            Label(action.title, systemImage: action.systemImage)
                        }
                    }
                }
            }

            if let lastActionMessage {
                Section("Last Action") {
                    Text(lastActionMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
    }
}
