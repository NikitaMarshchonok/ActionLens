import Contacts
import Foundation
import os

struct ContactDraft {
    var givenName: String?
    var familyName: String?
    var organizationName: String?
    var jobTitle: String?
    var email: String?
    var phone: String?
    var url: String?
    var emails: [String] = []
    var phones: [String] = []
    var urls: [String] = []

    var hasAnyValue: Bool {
        (givenName?.isEmpty == false)
            || (familyName?.isEmpty == false)
            || (organizationName?.isEmpty == false)
            || (jobTitle?.isEmpty == false)
            || (email?.isEmpty == false)
            || (phone?.isEmpty == false)
            || (url?.isEmpty == false)
            || emails.isEmpty == false
            || phones.isEmpty == false
            || urls.isEmpty == false
    }
}

protocol ContactActionServicing {
    func createContact(from draft: ContactDraft) async -> String
}

final class ContactsActionService: ContactActionServicing {
    private static let logger = Logger(subsystem: "ActionLens", category: "ContactsActions")
    private let contactStore = CNContactStore()

    func createContact(from draft: ContactDraft) async -> String {
        guard draft.hasAnyValue else {
            return "Not enough contact data to create contact."
        }

        let hasAccess = await requestContactAccess()
        guard hasAccess else {
            return "Contacts access denied. Enable access in Settings."
        }

        let contact = CNMutableContact()
        contact.givenName = draft.givenName ?? ""
        contact.familyName = draft.familyName ?? ""
        contact.organizationName = draft.organizationName ?? ""
        contact.jobTitle = draft.jobTitle ?? ""

        let emailValues = draft.emails.isEmpty ? [draft.email].compactMap { $0 } : draft.emails
        if emailValues.isEmpty == false {
            contact.emailAddresses = emailValues.map {
                CNLabeledValue(label: CNLabelWork, value: $0 as NSString)
            }
        }

        let phoneValues = draft.phones.isEmpty ? [draft.phone].compactMap { $0 } : draft.phones
        if phoneValues.isEmpty == false {
            contact.phoneNumbers = phoneValues.map {
                CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: $0))
            }
        }

        let urlValues = draft.urls.isEmpty ? [draft.url].compactMap { $0 } : draft.urls
        if urlValues.isEmpty == false {
            contact.urlAddresses = urlValues.map {
                CNLabeledValue(label: CNLabelURLAddressHomePage, value: $0 as NSString)
            }
        }

        let request = CNSaveRequest()
        request.add(contact, toContainerWithIdentifier: nil)

        do {
            try contactStore.execute(request)
            return "Contact created."
        } catch {
            Self.logger.error("Failed to create contact: \(error.localizedDescription, privacy: .public)")
            return "Could not create contact."
        }
    }

    private func requestContactAccess() async -> Bool {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                contactStore.requestAccess(for: .contacts) { granted, error in
                    if let error {
                        Self.logger.error("Contacts permission request failed: \(error.localizedDescription, privacy: .public)")
                    }
                    continuation.resume(returning: granted)
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}
