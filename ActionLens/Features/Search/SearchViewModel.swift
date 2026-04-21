import Foundation

struct SearchViewModel {
    let title: String

    init(environment: AppEnvironment = .live) {
        title = environment.shellService.appDisplayName
    }

    func filteredItems(from items: [InboxItem], using filter: InboxFilterState) -> [InboxItem] {
        InboxFiltering.filteredItems(from: items, using: filter)
    }

    func statusOptions(from items: [InboxItem]) -> [String] {
        InboxFiltering.statusOptions(from: items)
    }

    func sourceTypeOptions(from items: [InboxItem]) -> [String] {
        InboxFiltering.sourceTypeOptions(from: items)
    }

    func itemTypeOptions(from items: [InboxItem]) -> [String] {
        InboxFiltering.itemTypeOptions(from: items)
    }

    func subtitle(for item: InboxItem) -> String {
        let dateText = item.createdAt.formatted(date: .abbreviated, time: .shortened)
        let itemType = InboxItemType(rawValue: item.itemTypeRaw ?? "") ?? .general
        return "\(itemType.displayName) - \(item.sourceType) - \(item.status) - \(dateText)"
    }
}
