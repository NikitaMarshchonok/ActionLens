import Foundation

protocol ItemClassificationServicing {
    func classify(
        title: String,
        sourceType: String,
        extractedText: String?,
        entities: ExtractedEntities
    ) -> InboxItemType
}

struct LocalItemClassificationService: ItemClassificationServicing {
    func classify(
        title: String,
        sourceType: String,
        extractedText: String?,
        entities: ExtractedEntities
    ) -> InboxItemType {
        let normalized = "\(title) \(sourceType) \(extractedText ?? "")".lowercased()

        if entities.url != nil {
            return .link
        }

        if entities.email != nil || entities.phoneNumber != nil {
            return .contact
        }

        if entities.amount != nil
            || normalized.contains("invoice")
            || normalized.contains("bill")
            || normalized.contains("receipt")
            || normalized.contains("payment")
            || normalized.contains("total") {
            return .bill
        }

        if normalized.contains("booking")
            || normalized.contains("reservation")
            || normalized.contains("itinerary")
            || normalized.contains("flight")
            || normalized.contains("hotel") {
            return .booking
        }

        if entities.date != nil
            || entities.time != nil
            || normalized.contains("event")
            || normalized.contains("meeting")
            || normalized.contains("appointment") {
            return .event
        }

        if sourceType.lowercased() == "files"
            || normalized.contains("pdf")
            || normalized.contains("document")
            || normalized.contains("report")
            || normalized.contains("statement")
            || normalized.contains("warranty") {
            return .document
        }

        return .general
    }
}
