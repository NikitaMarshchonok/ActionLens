import Foundation
import SwiftData
import UIKit

struct InboxItemDetailViewModel {
    private let entityExtractionService: any EntityExtractionServicing
    private let smartActionService: any SmartActionServicing
    private let productivityActionService: any ProductivityActionServicing

    init(
        entityExtractionService: any EntityExtractionServicing = LocalEntityExtractionService(),
        smartActionService: any SmartActionServicing = LocalSmartActionService(),
        productivityActionService: any ProductivityActionServicing = EventKitActionService()
    ) {
        self.entityExtractionService = entityExtractionService
        self.smartActionService = smartActionService
        self.productivityActionService = productivityActionService
    }

    func createdAtText(for item: InboxItem) -> String {
        item.createdAt.formatted(date: .abbreviated, time: .shortened)
    }

    func itemTypeText(for item: InboxItem) -> String {
        let itemType = InboxItemType(rawValue: item.itemTypeRaw ?? "") ?? .general
        return itemType.displayName
    }

    func extractedEntities(for item: InboxItem) -> ExtractedEntities {
        guard let text = item.extractedText?.trimmingCharacters(in: .whitespacesAndNewlines),
              text.isEmpty == false else {
            return ExtractedEntities()
        }

        return entityExtractionService.extractEntities(from: text)
    }

    func suggestedActions(for item: InboxItem, entities: ExtractedEntities) -> [SmartSuggestedAction] {
        smartActionService.suggestedActions(entities: entities, currentStatus: item.status)
    }

    func performSuggestedAction(
        _ action: SmartSuggestedAction,
        for item: InboxItem,
        entities: ExtractedEntities,
        in modelContext: ModelContext,
        openURLHandler: (URL) -> Void
    ) async -> String {
        switch action {
        case .createReminder:
            return await productivityActionService.createReminder(
                title: item.title,
                dueDate: entities.detectedDate
            )
        case .createCalendarEvent:
            return await productivityActionService.createCalendarEvent(
                title: item.title,
                startDate: entities.detectedDate
            )
        case .saveForLater:
            item.status = "saved_for_later"
            try? modelContext.save()
            return "Item saved for later."
        case .markAsReviewed:
            item.status = "reviewed"
            try? modelContext.save()
            return "Item marked as reviewed."
        case .openLink(let value):
            guard let url = URL(string: value) else {
                return "Invalid URL."
            }
            openURLHandler(url)
            return "Opened link."
        case .copyEmail(let value):
            UIPasteboard.general.string = value
            return "Email copied."
        case .copyPhone(let value):
            UIPasteboard.general.string = value
            return "Phone copied."
        }
    }
}
