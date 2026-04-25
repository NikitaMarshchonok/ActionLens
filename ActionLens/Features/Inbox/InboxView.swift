import SwiftData
import SwiftUI

struct InboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\InboxItem.createdAt, order: .reverse)]) private var items: [InboxItem]
    @State private var filter = InboxFilterState()

    private let viewModel = InboxViewModel()

    var body: some View {
        let groupedSections = viewModel.groupedSections(from: items, using: filter)

        NavigationStack {
            List {
                ForEach(groupedSections) { section in
                    Section {
                        ForEach(section.items) { item in
                            NavigationLink {
                                InboxItemDetailView(item: item)
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(item.title)
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(2)

                                    HStack(spacing: 8) {
                                        MetadataPill(
                                            text: viewModel.itemTypeText(for: item),
                                            systemImage: typeIcon(for: item),
                                            tint: typeTint(for: item)
                                        )

                                        MetadataPill(
                                            text: viewModel.statusText(for: item),
                                            systemImage: statusIcon(for: item),
                                            tint: statusTint(for: item)
                                        )
                                    }

                                    HStack(spacing: 10) {
                                        Label(item.sourceType, systemImage: "tray")
                                        Label(viewModel.dateText(for: item), systemImage: "calendar")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    } header: {
                        HStack {
                            Text(section.group.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(section.items.count)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .textCase(.uppercase)
                    }
                }
            }
            .navigationTitle("Inbox")
            .searchable(text: $filter.searchText, prompt: "Search inbox")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Picker("Status", selection: $filter.selectedStatus) {
                            ForEach(viewModel.statusOptions(from: items), id: \.self) { status in
                                Text(status).tag(status)
                            }
                        }
                    } label: {
                        Label("Status", systemImage: "line.3.horizontal.decrease.circle")
                    }

                    Menu {
                        Picker("Source Type", selection: $filter.selectedSourceType) {
                            ForEach(viewModel.sourceTypeOptions(from: items), id: \.self) { sourceType in
                                Text(sourceType).tag(sourceType)
                            }
                        }
                    } label: {
                        Label("Source", systemImage: "line.3.horizontal.decrease.circle.fill")
                    }

                    Menu {
                        Picker("Item Type", selection: $filter.selectedItemType) {
                            ForEach(viewModel.itemTypeOptions(from: items), id: \.self) { itemType in
                                Text(itemType.capitalized).tag(itemType)
                            }
                        }
                    } label: {
                        Label("Type", systemImage: "tag")
                    }
                }
            }
            .overlay {
                if items.isEmpty {
                    ContentUnavailableView(
                        "Your Inbox Is Empty",
                        systemImage: "tray",
                        description: Text("Import from Photos or Files, or share from another app to get started.")
                    )
                } else if groupedSections.isEmpty {
                    ContentUnavailableView.search(text: filter.searchText)
                }
            }
            .task {
                viewModel.seedIfNeeded(modelContext: modelContext)
            }
        }
    }

    private func typeTint(for item: InboxItem) -> Color {
        let itemType = InboxItemType(rawValue: item.itemTypeRaw ?? "") ?? .general
        switch itemType {
        case .contact:
            return .indigo
        case .event:
            return .blue
        case .bill:
            return .orange
        case .booking:
            return .teal
        case .link:
            return .purple
        case .document:
            return .brown
        case .general:
            return .gray
        }
    }

    private func statusTint(for item: InboxItem) -> Color {
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

    private func typeIcon(for item: InboxItem) -> String {
        let itemType = InboxItemType(rawValue: item.itemTypeRaw ?? "") ?? .general
        switch itemType {
        case .contact:
            return "person.crop.circle"
        case .event:
            return "calendar"
        case .bill:
            return "creditcard"
        case .booking:
            return "airplane"
        case .link:
            return "link"
        case .document:
            return "doc.text"
        case .general:
            return "square.grid.2x2"
        }
    }

    private func statusIcon(for item: InboxItem) -> String {
        switch item.status.lowercased() {
        case "reviewed", "done", "completed":
            return "checkmark.circle"
        case "saved_for_later":
            return "bookmark"
        case "in_review":
            return "clock"
        default:
            return "circle"
        }
    }
}

private struct MetadataPill: View {
    let text: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }
}
