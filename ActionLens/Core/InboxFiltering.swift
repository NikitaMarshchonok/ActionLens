import Foundation

struct InboxFilterState {
    static let allValue = "All"

    var searchText: String = ""
    var selectedStatus: String = allValue
    var selectedSourceType: String = allValue
    var selectedItemType: String = allValue
}

enum InboxFiltering {
    static func filteredItems(from items: [InboxItem], using filter: InboxFilterState) -> [InboxItem] {
        items.filter { item in
            let matchesTitle = filter.searchText.isEmpty
                || item.title.localizedCaseInsensitiveContains(filter.searchText)
            let matchesStatus = filter.selectedStatus == InboxFilterState.allValue
                || item.status == filter.selectedStatus
            let matchesSource = filter.selectedSourceType == InboxFilterState.allValue
                || item.sourceType == filter.selectedSourceType
            let itemType = InboxItemType(rawValue: item.itemTypeRaw ?? "") ?? .general
            let matchesItemType = filter.selectedItemType == InboxFilterState.allValue
                || itemType.rawValue == filter.selectedItemType

            return matchesTitle && matchesStatus && matchesSource && matchesItemType
        }
    }

    static func statusOptions(from items: [InboxItem]) -> [String] {
        let values = Set(items.map(\.status)).sorted()
        return [InboxFilterState.allValue] + values
    }

    static func sourceTypeOptions(from items: [InboxItem]) -> [String] {
        let values = Set(items.map(\.sourceType)).sorted()
        return [InboxFilterState.allValue] + values
    }

    static func itemTypeOptions(from items: [InboxItem]) -> [String] {
        let values = Set(items.map { item in
            let resolvedType = InboxItemType(rawValue: item.itemTypeRaw ?? "") ?? .general
            return resolvedType.rawValue
        }).sorted()
        return [InboxFilterState.allValue] + values
    }
}
