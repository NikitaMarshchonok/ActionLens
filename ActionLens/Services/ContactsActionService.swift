import Contacts
import Foundation

struct ContactDraft {
    var givenName: String?
    var familyName: String?
    var organizationName: String?
    var email: String?
    var phone: String?
    var url: String?

    var hasAnyValue: Bool {
        (givenName?.isEmpty == false)
            || (familyName?.isEmpty == false)
            || (organizationName?.isEmpty == false)
            || (email?.isEmpty == false)
            || (phone?.isEmpty == false)
            || (url?.isEmpty == false)
    }
}

protocol ContactActionServicing {
    func createContact(from draft: ContactDraft) async -> String
}

final class ContactsActionService: ContactActionServicing {
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

        if let email = draft.email, email.isEmpty == false {
            contact.emailAddresses = [CNLabeledValue(label: CNLabelWork, value: email as NSString)]
        }

        if let phone = draft.phone, phone.isEmpty == false {
            let phoneValue = CNPhoneNumber(stringValue: phone)
            contact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMobile, value: phoneValue)]
        }

        if let url = draft.url, url.isEmpty == false {
            contact.urlAddresses = [CNLabeledValue(label: CNLabelURLAddressHomePage, value: url as NSString)]
        }

        let request = CNSaveRequest()
        request.add(contact, toContainerWithIdentifier: nil)

        do {
            try contactStore.execute(request)
            return "Contact created."
        } catch {
            return "Could not create contact."
        }
    }

    private func requestContactAccess() async -> Bool {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                contactStore.requestAccess(for: .contacts) { granted, _ in
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
