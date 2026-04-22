import Foundation

enum SmartSuggestedAction: Hashable {
    case createReminder
    case createCalendarEvent
    case createContact
    case saveForLater
    case markAsReviewed
    case openLink(String)
    case copyEmail(String)
    case copyPhone(String)

    var id: String {
        switch self {
        case .createReminder:
            return "createReminder"
        case .createCalendarEvent:
            return "createCalendarEvent"
        case .createContact:
            return "createContact"
        case .saveForLater:
            return "saveForLater"
        case .markAsReviewed:
            return "markAsReviewed"
        case .openLink(let value):
            return "openLink:\(value)"
        case .copyEmail(let value):
            return "copyEmail:\(value)"
        case .copyPhone(let value):
            return "copyPhone:\(value)"
        }
    }

    var title: String {
        switch self {
        case .createReminder:
            return "Create Reminder"
        case .createCalendarEvent:
            return "Create Calendar Event"
        case .createContact:
            return "Create Contact"
        case .saveForLater:
            return "Save for Later"
        case .markAsReviewed:
            return "Mark as Reviewed"
        case .openLink:
            return "Open Link"
        case .copyEmail:
            return "Copy Email"
        case .copyPhone:
            return "Copy Phone"
        }
    }

    var systemImage: String {
        switch self {
        case .createReminder:
            return "bell.badge"
        case .createCalendarEvent:
            return "calendar.badge.plus"
        case .createContact:
            return "person.crop.circle.badge.plus"
        case .saveForLater:
            return "bookmark"
        case .markAsReviewed:
            return "checkmark.circle"
        case .openLink:
            return "link"
        case .copyEmail:
            return "envelope"
        case .copyPhone:
            return "phone"
        }
    }
}

protocol SmartActionServicing {
    func suggestedActions(entities: ExtractedEntities, currentStatus: String, itemTypeRaw: String?) -> [SmartSuggestedAction]
}

struct LocalSmartActionService: SmartActionServicing {
    func suggestedActions(
        entities: ExtractedEntities,
        currentStatus: String,
        itemTypeRaw: String?
    ) -> [SmartSuggestedAction] {
        var actions: [SmartSuggestedAction] = []

        if entities.date != nil || entities.time != nil {
            actions.append(.createReminder)
            actions.append(.createCalendarEvent)
        }

        for url in entities.urls {
            actions.append(.openLink(url))
        }
        if entities.urls.isEmpty, let url = entities.url {
            actions.append(.openLink(url))
        }

        for email in entities.emails {
            actions.append(.copyEmail(email))
        }
        if entities.emails.isEmpty, let email = entities.email {
            actions.append(.copyEmail(email))
        }

        for phoneNumber in entities.phoneNumbers {
            actions.append(.copyPhone(phoneNumber))
        }
        if entities.phoneNumbers.isEmpty, let phoneNumber = entities.phoneNumber {
            actions.append(.copyPhone(phoneNumber))
        }

        let itemType = InboxItemType(rawValue: itemTypeRaw ?? "") ?? .general
        let hasContactLikeValue = entities.emails.isEmpty == false
            || entities.phoneNumbers.isEmpty == false
            || entities.email != nil
            || entities.phoneNumber != nil
            || (entities.urlHost != nil && itemType == .contact)
        if hasContactLikeValue {
            actions.append(.createContact)
        }

        if currentStatus != "saved_for_later" {
            actions.append(.saveForLater)
        }

        if currentStatus != "reviewed" {
            actions.append(.markAsReviewed)
        }

        var seen: Set<String> = []
        var deduplicated: [SmartSuggestedAction] = []
        for action in actions {
            if seen.contains(action.id) { continue }
            seen.insert(action.id)
            deduplicated.append(action)
        }

        return deduplicated
    }
}
