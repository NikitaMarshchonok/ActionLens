import Foundation
import SwiftData
import UIKit

struct InboxItemDetailViewModel {
    enum ContactQuickAction: Hashable {
        case call(String)
        case email(String)
        case openWebsite(String)
        case createContact
        case copyAllContactInfo(String)

        var id: String {
            switch self {
            case .call(let value):
                return "call:\(value)"
            case .email(let value):
                return "email:\(value)"
            case .openWebsite(let value):
                return "website:\(value)"
            case .createContact:
                return "createContact"
            case .copyAllContactInfo:
                return "copyAllInfo"
            }
        }

        var title: String {
            switch self {
            case .call(let value):
                return "Call \(value)"
            case .email(let value):
                return "Email \(value)"
            case .openWebsite(let value):
                return "Open \(value)"
            case .createContact:
                return "Create Contact"
            case .copyAllContactInfo:
                return "Copy All Contact Info"
            }
        }

        var systemImage: String {
            switch self {
            case .call:
                return "phone"
            case .email:
                return "envelope"
            case .openWebsite:
                return "globe"
            case .createContact:
                return "person.crop.circle.badge.plus"
            case .copyAllContactInfo:
                return "doc.on.doc"
            }
        }
    }

    private let entityExtractionService: any EntityExtractionServicing
    private let smartActionService: any SmartActionServicing
    private let productivityActionService: any ProductivityActionServicing
    private let contactActionService: any ContactActionServicing

    init(
        entityExtractionService: any EntityExtractionServicing = LocalEntityExtractionService(),
        smartActionService: any SmartActionServicing = LocalSmartActionService(),
        productivityActionService: any ProductivityActionServicing = EventKitActionService(),
        contactActionService: any ContactActionServicing = ContactsActionService()
    ) {
        self.entityExtractionService = entityExtractionService
        self.smartActionService = smartActionService
        self.productivityActionService = productivityActionService
        self.contactActionService = contactActionService
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
        smartActionService.suggestedActions(
            entities: entities,
            currentStatus: item.status,
            itemTypeRaw: item.itemTypeRaw
        )
    }

    func contactQuickActions(for item: InboxItem, entities: ExtractedEntities) -> [ContactQuickAction] {
        var actions: [ContactQuickAction] = []

        let phones = entities.phoneNumbers.isEmpty ? [entities.phoneNumber].compactMap { $0 } : entities.phoneNumbers
        let emails = entities.emails.isEmpty ? [entities.email].compactMap { $0 } : entities.emails
        let websites = entities.urls.isEmpty ? [entities.url].compactMap { $0 } : entities.urls

        for phone in phones {
            actions.append(.call(phone))
        }
        for email in emails {
            actions.append(.email(email))
        }
        for website in websites {
            actions.append(.openWebsite(website))
        }

        if itemTypeText(for: item) == InboxItemType.contact.displayName
            || phones.isEmpty == false
            || emails.isEmpty == false
            || websites.isEmpty == false
            || entities.personName != nil
            || entities.companyName != nil {
            actions.append(.createContact)
        }

        if let copyPayload = combinedContactInfoText(entities: entities), copyPayload.isEmpty == false {
            actions.append(.copyAllContactInfo(copyPayload))
        }

        var seen: Set<String> = []
        return actions.filter {
            if seen.contains($0.id) { return false }
            seen.insert($0.id)
            return true
        }
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
        case .createContact:
            let draft = makeContactDraft(for: item, entities: entities)
            return await contactActionService.createContact(from: draft)
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

    func performContactQuickAction(
        _ action: ContactQuickAction,
        for item: InboxItem,
        entities: ExtractedEntities,
        openURLHandler: (URL) -> Void
    ) async -> String {
        switch action {
        case .call(let value):
            let sanitized = value.filter { "0123456789+".contains($0) }
            guard let url = URL(string: "tel://\(sanitized)") else {
                return "Invalid phone number."
            }
            openURLHandler(url)
            return "Calling \(value)."
        case .email(let value):
            guard let encoded = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: "mailto:\(encoded)") else {
                return "Invalid email."
            }
            openURLHandler(url)
            return "Opening email composer."
        case .openWebsite(let value):
            guard let url = URL(string: value) else {
                return "Invalid URL."
            }
            openURLHandler(url)
            return "Opening website."
        case .createContact:
            let draft = makeContactDraft(for: item, entities: entities)
            return await contactActionService.createContact(from: draft)
        case .copyAllContactInfo(let payload):
            UIPasteboard.general.string = payload
            return "All contact info copied."
        }
    }

    private func makeContactDraft(for item: InboxItem, entities: ExtractedEntities) -> ContactDraft {
        var givenName: String?
        var familyName: String?

        if let personNameLine = entities.personName {
            let parts = personNameLine.split(separator: " ").map(String.init)
            if parts.isEmpty == false {
                givenName = parts.first
                if parts.count >= 2 {
                    familyName = parts.dropFirst().joined(separator: " ")
                }
            }
        }

        return ContactDraft(
            givenName: givenName,
            familyName: familyName,
            organizationName: entities.companyName,
            jobTitle: entities.jobTitle,
            email: entities.email,
            phone: entities.phoneNumbers.first ?? entities.phoneNumber,
            url: entities.urls.first ?? entities.url,
            emails: entities.emails,
            phones: entities.phoneNumbers,
            urls: entities.urls
        )
    }

    private func combinedContactInfoText(entities: ExtractedEntities) -> String? {
        var lines: [String] = []

        if let personName = entities.personName {
            lines.append("Name: \(personName)")
        }
        if let companyName = entities.companyName {
            lines.append("Company: \(companyName)")
        }
        if let role = entities.jobTitle {
            lines.append("Role: \(role)")
        }
        for email in entities.emails {
            lines.append("Email: \(email)")
        }
        for phone in entities.phoneNumbers {
            lines.append("Phone: \(phone)")
        }
        for url in entities.urls {
            lines.append("Website: \(url)")
        }

        guard lines.isEmpty == false else { return nil }
        return lines.joined(separator: "\n")
    }
}
