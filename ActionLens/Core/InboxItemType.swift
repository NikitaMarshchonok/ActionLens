import Foundation

enum InboxItemType: String, CaseIterable {
    case general
    case event
    case bill
    case booking
    case contact
    case link
    case document

    var displayName: String {
        switch self {
        case .general:
            return "General"
        case .event:
            return "Event"
        case .bill:
            return "Bill"
        case .booking:
            return "Booking"
        case .contact:
            return "Contact"
        case .link:
            return "Link"
        case .document:
            return "Document"
        }
    }
}
