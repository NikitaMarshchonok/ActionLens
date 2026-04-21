import SwiftData
import SwiftUI

struct SearchView: View {
    @Query(sort: [SortDescriptor(\InboxItem.createdAt, order: .reverse)]) private var items: [InboxItem]
    @State private var filter = InboxFilterState()

    private let viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.filteredItems(from: items, using: filter)) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.headline)

                        Text(viewModel.subtitle(for: item))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $filter.searchText, prompt: "Search title")
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
                        "\(viewModel.title) Search",
                        systemImage: "magnifyingglass",
                        description: Text("No inbox items yet.")
                    )
                } else if viewModel.filteredItems(from: items, using: filter).isEmpty {
                    ContentUnavailableView.search(text: filter.searchText)
                }
            }
        }
    }
}
