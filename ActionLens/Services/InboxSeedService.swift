import Foundation
import SwiftData

struct InboxSeedService {
    func seedIfNeeded(in modelContext: ModelContext) {
        var descriptor = FetchDescriptor<InboxItem>()
        descriptor.fetchLimit = 1
        let hasAnyItems = ((try? modelContext.fetch(descriptor)) ?? []).isEmpty == false
        guard hasAnyItems == false else { return }

        let now = Date()
        let mockItems = [
            InboxItem(
                title: "Grocery Receipt - Green Market",
                sourceType: "Camera",
                createdAt: now.addingTimeInterval(-15 * 60),
                status: "new"
            ),
            InboxItem(
                title: "Warranty Card - Coffee Machine",
                sourceType: "Photo Library",
                createdAt: now.addingTimeInterval(-3 * 60 * 60),
                status: "in_review"
            ),
            InboxItem(
                title: "Invoice - Design Subscription",
                sourceType: "Manual",
                createdAt: now.addingTimeInterval(-26 * 60 * 60),
                status: "done"
            )
        ]

        for item in mockItems {
            modelContext.insert(item)
        }

        try? modelContext.save()
    }
}
