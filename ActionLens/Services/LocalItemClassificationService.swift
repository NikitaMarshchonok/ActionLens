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
        let billScore = billSignalScore(in: normalized, entities: entities)
        let contactScore = contactSignalScore(in: normalized, entities: entities, extractedText: extractedText)

        if billScore >= 2 {
            return .bill
        }

        // Business-card-like content should be Contact even when URL exists.
        if contactScore >= 3 {
            return .contact
        }

        if entities.urls.isEmpty == false || entities.url != nil {
            return .link
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

    private func billSignalScore(in normalized: String, entities: ExtractedEntities) -> Int {
        var score = 0

        if entities.amount != nil {
            score += 2
        }

        if normalized.contains("invoice")
            || normalized.contains("bill")
            || normalized.contains("receipt")
            || normalized.contains("payment")
            || normalized.contains("total") {
            score += 1
        }

        return score
    }

    private func contactSignalScore(
        in normalized: String,
        entities: ExtractedEntities,
        extractedText: String?
    ) -> Int {
        var score = 0

        let emailCount = entities.emails.isEmpty ? (entities.email == nil ? 0 : 1) : entities.emails.count
        if emailCount >= 2 {
            score += 3
        } else if emailCount == 1 {
            score += 2
        }

        let phoneCount = entities.phoneNumbers.isEmpty
            ? (entities.phoneNumber == nil ? 0 : 1)
            : entities.phoneNumbers.count
        if phoneCount >= 2 {
            score += 2
        } else if phoneCount == 1 {
            score += 1
        }

        if entities.urlHosts.isEmpty == false || entities.urlHost != nil {
            score += 1
        }

        if hasRoleLikeKeywords(in: normalized) {
            score += 1
        }

        if hasCompanyLikeKeywords(in: normalized) {
            score += 1
        }

        if hasPersonLikePattern(in: extractedText ?? "") {
            score += 1
        }

        return score
    }

    private func hasRoleLikeKeywords(in normalized: String) -> Bool {
        let keywords = [
            "manager", "director", "founder", "ceo", "cto", "cfo",
            "sales", "marketing", "engineer", "consultant", "realtor"
        ]
        return keywords.contains { normalized.contains($0) }
    }

    private func hasCompanyLikeKeywords(in normalized: String) -> Bool {
        let keywords = [
            "inc", "llc", "ltd", "corp", "company", "studio", "agency",
            "group", "solutions", "technologies", "systems"
        ]
        return keywords.contains { normalized.contains($0) }
    }

    private func hasPersonLikePattern(in text: String) -> Bool {
        // Heuristic: a short OCR line with two capitalized words often looks like a name.
        let lines = text
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        for line in lines.prefix(5) {
            let words = line.split(separator: " ")
            guard words.count >= 2, words.count <= 3 else { continue }
            let startsWithCapital = words.allSatisfy { word in
                guard let first = word.first else { return false }
                return first.isUppercase
            }
            if startsWithCapital {
                return true
            }
        }
        return false
    }
}
