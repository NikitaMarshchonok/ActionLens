import Foundation
import SwiftData

struct DemoShowcaseReport {
    let createdCount: Int
    let removedCount: Int
    let message: String
}

protocol DemoShowcaseServicing {
    @MainActor func seedDemoItems(in modelContext: ModelContext) -> DemoShowcaseReport
    @MainActor func clearDemoItems(in modelContext: ModelContext) -> DemoShowcaseReport
}

struct DemoShowcaseService: DemoShowcaseServicing {
    @MainActor
    func seedDemoItems(in modelContext: ModelContext) -> DemoShowcaseReport {
        let existingDemoCount = demoItems(in: modelContext).count
        guard existingDemoCount == 0 else {
            return DemoShowcaseReport(
                createdCount: 0,
                removedCount: 0,
                message: "Demo items already seeded."
            )
        }

        let now = Date()
        let items = demoPayloads(relativeTo: now)
        for item in items {
            modelContext.insert(item)
        }
        try? modelContext.save()

        return DemoShowcaseReport(
            createdCount: items.count,
            removedCount: 0,
            message: "Seeded \(items.count) demo items."
        )
    }

    @MainActor
    func clearDemoItems(in modelContext: ModelContext) -> DemoShowcaseReport {
        let items = demoItems(in: modelContext)
        guard items.isEmpty == false else {
            return DemoShowcaseReport(
                createdCount: 0,
                removedCount: 0,
                message: "No demo items to clear."
            )
        }

        for item in items {
            modelContext.delete(item)
        }
        try? modelContext.save()

        return DemoShowcaseReport(
            createdCount: 0,
            removedCount: items.count,
            message: "Cleared \(items.count) demo items."
        )
    }

    @MainActor
    private func demoItems(in modelContext: ModelContext) -> [InboxItem] {
        let descriptor = FetchDescriptor<InboxItem>()
        let items = (try? modelContext.fetch(descriptor)) ?? []
        return items.filter(\.isDemoItem)
    }

    private func demoPayloads(relativeTo now: Date) -> [InboxItem] {
        [
            InboxItem(
                title: "Green Market Receipt",
                sourceType: "Photos",
                createdAt: now.addingTimeInterval(-20 * 60),
                status: "new",
                extractedText: """
                Green Market
                Receipt #A-9281
                Date: Apr 20, 2026
                Total: $48.70
                support@greenmarket.com
                +1 (415) 555-1001
                https://greenmarket.com/receipts
                """,
                itemTypeRaw: InboxItemType.bill.rawValue,
                isDemoItem: true
            ),
            InboxItem(
                title: "City Design Meetup Flyer",
                sourceType: "Share Image",
                createdAt: now.addingTimeInterval(-2 * 60 * 60),
                status: "new",
                extractedText: """
                City Design Meetup
                Apr 22, 2026 7:30 PM
                Riverside Hall
                RSVP: https://events.example.com/design-meetup
                """,
                itemTypeRaw: InboxItemType.event.rawValue,
                isDemoItem: true
            ),
            InboxItem(
                title: "Avery Stone Business Card",
                sourceType: "Photos",
                createdAt: now.addingTimeInterval(-4 * 24 * 60 * 60),
                status: "in_review",
                extractedText: """
                Avery Stone
                Senior Account Manager
                Northline Solutions LLC
                avery.stone@northline.com
                contact@northline.com
                +1 (415) 555-2001
                +1 (415) 555-2002
                https://northline.com
                """,
                itemTypeRaw: InboxItemType.contact.rawValue,
                isDemoItem: true
            ),
            InboxItem(
                title: "Launch Portal Link Card",
                sourceType: "Share URL",
                createdAt: now.addingTimeInterval(-30 * 60),
                status: "new",
                extractedText: """
                Product Launch Portal
                https://launch.example.com
                Campaign Window: May 29, 2026
                """,
                itemTypeRaw: InboxItemType.link.rawValue,
                isDemoItem: true
            ),
            InboxItem(
                title: "Project Brief Document",
                sourceType: "Files",
                createdAt: now.addingTimeInterval(-24 * 60 * 60),
                status: "reviewed",
                extractedText: """
                ActionLens Internal Brief
                Q2 rollout summary and milestones.
                Owner: product-team@example.com
                """,
                itemTypeRaw: InboxItemType.document.rawValue,
                isDemoItem: true
            )
        ]
    }
}
