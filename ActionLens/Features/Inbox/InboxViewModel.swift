import Foundation
import SwiftData

struct InboxViewModel {
    let title: String
    private let seedService: InboxSeedService
    private let urgencyGroupingService: any InboxUrgencyGroupingServicing

    init(
        environment: AppEnvironment = .live,
        seedService: InboxSeedService = InboxSeedService(),
        urgencyGroupingService: (any InboxUrgencyGroupingServicing)? = nil
    ) {
        title = environment.shellService.appDisplayName
        self.seedService = seedService
        self.urgencyGroupingService = urgencyGroupingService ?? environment.urgencyGroupingService
    }

    func seedIfNeeded(modelContext: ModelContext) {
        seedService.seedIfNeeded(in: modelContext)
    }

    func subtitle(for item: InboxItem) -> String {
        let dateText = item.createdAt.formatted(date: .abbreviated, time: .shortened)
        let typeText = itemTypeText(for: item)
        return "\(typeText) - \(item.sourceType) - \(item.status) - \(dateText)"
    }

    func statusText(for item: InboxItem) -> String {
        item.status
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    func dateText(for item: InboxItem) -> String {
        item.createdAt.formatted(date: .abbreviated, time: .shortened)
    }

    func filteredItems(from items: [InboxItem], using filter: InboxFilterState) -> [InboxItem] {
        InboxFiltering.filteredItems(from: items, using: filter)
    }

    func groupedSections(from items: [InboxItem], using filter: InboxFilterState) -> [InboxUrgencySection] {
        let filtered = filteredItems(from: items, using: filter)
        return urgencyGroupingService.groupedSections(from: filtered, now: .now)
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

    func itemTypeText(for item: InboxItem) -> String {
        let itemType = InboxItemType(rawValue: item.itemTypeRaw ?? "") ?? .general
        return itemType.displayName
    }
}
