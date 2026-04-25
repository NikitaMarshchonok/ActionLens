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
        let contactQuickActions = viewModel.contactQuickActions(for: item, entities: detectedEntities)
        let suggestedActions = viewModel
            .suggestedActions(for: item, entities: detectedEntities)
            .filter { action in
                if case .createContact = action, contactQuickActions.isEmpty == false {
                    return false
                }
                return true
            }

        List {
            Section("Item Details") {
                LabeledContent("Title") {
                    Text(item.title)
                        .font(.body.weight(.semibold))
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("Type") {
                    MetadataBadge(text: viewModel.itemTypeText(for: item), tint: .indigo)
                }
                LabeledContent("Source Type") {
                    Text(item.sourceType)
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Status") {
                    MetadataBadge(text: item.status.replacingOccurrences(of: "_", with: " ").capitalized, tint: statusTint)
                }
                LabeledContent("Created At") {
                    Text(viewModel.createdAtText(for: item))
                        .foregroundStyle(.secondary)
                }
            }

            Section("Extracted Text") {
                if let extractedText = item.extractedText, extractedText.isEmpty == false {
                    Text(extractedText)
                        .font(.body)
                        .textSelection(.enabled)
                } else {
                    Text("No text was found for this item.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Detected Values") {
                if detectedEntities.isEmpty {
                    Text("No details were detected yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    if let value = detectedEntities.date {
                        DetectedValueRow(label: "Date", value: value, systemImage: "calendar")
                    }
                    if let value = detectedEntities.time {
                        DetectedValueRow(label: "Time", value: value, systemImage: "clock")
                    }
                    if let value = detectedEntities.amount {
                        DetectedValueRow(label: "Amount", value: value, systemImage: "creditcard")
                    }
                    if detectedEntities.emails.isEmpty == false {
                        ForEach(Array(detectedEntities.emails.enumerated()), id: \.offset) { index, value in
                            DetectedValueRow(label: "Email \(index + 1)", value: value, systemImage: "envelope")
                        }
                    } else if let value = detectedEntities.email {
                        DetectedValueRow(label: "Email 1", value: value, systemImage: "envelope")
                    }
                    if detectedEntities.phoneNumbers.isEmpty == false {
                        ForEach(Array(detectedEntities.phoneNumbers.enumerated()), id: \.offset) { index, value in
                            DetectedValueRow(label: "Phone \(index + 1)", value: value, systemImage: "phone")
                        }
                    } else if let value = detectedEntities.phoneNumber {
                        DetectedValueRow(label: "Phone 1", value: value, systemImage: "phone")
                    }
                    if detectedEntities.urls.isEmpty == false {
                        ForEach(Array(detectedEntities.urls.enumerated()), id: \.offset) { index, value in
                            DetectedValueRow(label: "URL \(index + 1)", value: value, systemImage: "link")
                        }
                    } else if let value = detectedEntities.url {
                        DetectedValueRow(label: "URL 1", value: value, systemImage: "link")
                    }
                }
            }

            if hasContactInsights(detectedEntities) {
                Section("Contact Insights") {
                    if let personName = detectedEntities.personName {
                        LabeledContent("Name", value: personName)
                    }
                    if let companyName = detectedEntities.companyName {
                        LabeledContent("Company", value: companyName)
                    }
                    if let jobTitle = detectedEntities.jobTitle {
                        LabeledContent("Role", value: jobTitle)
                    }
                    if detectedEntities.emails.isEmpty == false {
                        LabeledContent("Emails", value: "\(detectedEntities.emails.count)")
                    }
                    if detectedEntities.phoneNumbers.isEmpty == false {
                        LabeledContent("Phones", value: "\(detectedEntities.phoneNumbers.count)")
                    }
                    if detectedEntities.urls.isEmpty == false {
                        LabeledContent("Links", value: "\(detectedEntities.urls.count)")
                    }
                }
            }

            if contactQuickActions.isEmpty == false {
                Section("Contact Quick Actions") {
                    ForEach(contactQuickActions, id: \.id) { action in
                        Button {
                            Task {
                                lastActionMessage = await viewModel.performContactQuickAction(
                                    action,
                                    for: item,
                                    entities: detectedEntities,
                                    openURLHandler: { url in
                                        openURL(url)
                                    }
                                )
                            }
                        } label: {
                            Label(action.title, systemImage: action.systemImage)
                                .font(.body.weight(.medium))
                        }
                        .accessibilityHint("Performs this action for the current item.")
                    }
                }
            }

            Section("Suggested Actions") {
                if suggestedActions.isEmpty {
                    Text("No suggested actions are available for this item yet.")
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
                                .font(.body.weight(.medium))
                        }
                        .accessibilityHint("Performs this suggested action.")
                    }
                }
            }

            if let lastActionMessage {
                Section("Last Action") {
                    Label(lastActionMessage, systemImage: lastActionIcon(for: lastActionMessage))
                        .font(.subheadline)
                        .foregroundStyle(lastActionTint(for: lastActionMessage))
                        .textSelection(.enabled)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusTint: Color {
        switch item.status.lowercased() {
        case "reviewed", "done", "completed":
            return .green
        case "saved_for_later":
            return .orange
        case "in_review":
            return .blue
        default:
            return .gray
        }
    }

    private func hasContactInsights(_ entities: ExtractedEntities) -> Bool {
        entities.personName != nil
            || entities.companyName != nil
            || entities.jobTitle != nil
            || entities.emails.isEmpty == false
            || entities.phoneNumbers.isEmpty == false
            || entities.urls.isEmpty == false
    }

    private func lastActionTint(for message: String) -> Color {
        let normalized = message.lowercased()
        if normalized.contains("could not")
            || normalized.contains("denied")
            || normalized.contains("invalid")
            || normalized.contains("failed") {
            return .red
        }
        return .secondary
    }

    private func lastActionIcon(for message: String) -> String {
        let normalized = message.lowercased()
        if normalized.contains("could not")
            || normalized.contains("denied")
            || normalized.contains("invalid")
            || normalized.contains("failed") {
            return "exclamationmark.triangle"
        }
        return "checkmark.circle"
    }
}

private struct MetadataBadge: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.14))
            .clipShape(Capsule())
    }
}

private struct DetectedValueRow: View {
    let label: String
    let value: String
    let systemImage: String

    var body: some View {
        LabeledContent {
            Text(value)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        } label: {
            Label(label, systemImage: systemImage)
                .foregroundStyle(.secondary)
        }
    }
}
