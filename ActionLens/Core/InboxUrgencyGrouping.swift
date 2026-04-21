import Foundation

enum InboxUrgencyGroup: String, CaseIterable {
    case needsReview
    case today
    case soon
    case later
    case completed

    var title: String {
        switch self {
        case .needsReview:
            return "Needs Review"
        case .today:
            return "Today"
        case .soon:
            return "Soon"
        case .later:
            return "Later"
        case .completed:
            return "Completed"
        }
    }
}

struct InboxUrgencySection: Identifiable {
    let group: InboxUrgencyGroup
    let items: [InboxItem]

    var id: String { group.rawValue }
}

protocol InboxUrgencyGroupingServicing {
    func groupedSections(from items: [InboxItem], now: Date) -> [InboxUrgencySection]
}

struct LocalInboxUrgencyGroupingService: InboxUrgencyGroupingServicing {
    private let entityExtractionService: any EntityExtractionServicing

    init(entityExtractionService: any EntityExtractionServicing = LocalEntityExtractionService()) {
        self.entityExtractionService = entityExtractionService
    }

    func groupedSections(from items: [InboxItem], now: Date = .now) -> [InboxUrgencySection] {
        var groups: [InboxUrgencyGroup: [InboxItem]] = [:]
        let calendar = Calendar.current

        for item in items {
            let group = urgencyGroup(for: item, now: now, calendar: calendar)
            groups[group, default: []].append(item)
        }

        return InboxUrgencyGroup.allCases.compactMap { group in
            guard let groupedItems = groups[group], groupedItems.isEmpty == false else {
                return nil
            }

            let sortedItems = groupedItems.sorted { $0.createdAt > $1.createdAt }
            return InboxUrgencySection(group: group, items: sortedItems)
        }
    }

    private func urgencyGroup(for item: InboxItem, now: Date, calendar: Calendar) -> InboxUrgencyGroup {
        let normalizedStatus = item.status.lowercased()

        if ["done", "completed", "reviewed"].contains(normalizedStatus) {
            return .completed
        }

        let detectedDate = detectedDate(from: item)
        let referenceDate = detectedDate ?? item.createdAt

        if detectedDate == nil,
           ["new", "in_review"].contains(normalizedStatus),
           item.createdAt <= calendar.date(byAdding: .day, value: -2, to: now) ?? now {
            return .needsReview
        }

        if calendar.isDate(referenceDate, inSameDayAs: now) {
            return .today
        }

        let soonBoundary = calendar.date(byAdding: .day, value: 3, to: now) ?? now
        if referenceDate <= soonBoundary {
            return .soon
        }

        return .later
    }

    private func detectedDate(from item: InboxItem) -> Date? {
        guard let extractedText = item.extractedText?.trimmingCharacters(in: .whitespacesAndNewlines),
              extractedText.isEmpty == false else {
            return nil
        }

        let entities = entityExtractionService.extractEntities(from: extractedText)
        return entities.detectedDate
    }
}
