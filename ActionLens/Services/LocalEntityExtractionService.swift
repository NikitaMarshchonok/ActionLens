import Foundation

struct ExtractedEntities {
    var date: String?
    var time: String?
    var amount: String?
    var email: String?
    var phoneNumber: String?
    var url: String?
    var detectedDate: Date?
    var emails: [String] = []
    var phoneNumbers: [String] = []
    var urls: [String] = []
    var urlHost: String?
    var urlHosts: [String] = []

    var isEmpty: Bool {
        date == nil
            && time == nil
            && amount == nil
            && email == nil
            && phoneNumber == nil
            && url == nil
            && emails.isEmpty
            && phoneNumbers.isEmpty
            && urls.isEmpty
    }
}

protocol EntityExtractionServicing {
    func extractEntities(from text: String) -> ExtractedEntities
}

struct LocalEntityExtractionService: EntityExtractionServicing {
    func extractEntities(from text: String) -> ExtractedEntities {
        var entities = ExtractedEntities()

        entities.emails = allMatches(
            for: "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}",
            in: text,
            options: [.caseInsensitive]
        )
        entities.email = entities.emails.first

        entities.amount = firstMatch(
            for: "(?:[$€£]|USD\\s?)\\d+(?:[\\.,]\\d{2})?",
            in: text,
            options: [.caseInsensitive]
        )

        let detectorTypes: NSTextCheckingResult.CheckingType = [.date, .link, .phoneNumber]
        if let detector = try? NSDataDetector(types: detectorTypes.rawValue) {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            let matches = detector.matches(in: text, options: [], range: range)

            for match in matches {
                if let phoneNumber = match.phoneNumber,
                   entities.phoneNumbers.contains(phoneNumber) == false {
                    entities.phoneNumbers.append(phoneNumber)
                }
                if let url = match.url, url.scheme != "mailto" {
                    let urlString = url.absoluteString
                    if entities.urls.contains(urlString) == false {
                        entities.urls.append(urlString)
                    }
                    if let host = url.host, entities.urlHosts.contains(host) == false {
                        entities.urlHosts.append(host)
                    }
                }

                if let dateValue = match.date {
                    if entities.detectedDate == nil {
                        entities.detectedDate = dateValue
                    }
                    if entities.date == nil {
                        entities.date = dateValue.formatted(date: .abbreviated, time: .omitted)
                    }
                    if entities.time == nil {
                        entities.time = dateValue.formatted(date: .omitted, time: .shortened)
                    }
                }
            }
        }

        entities.phoneNumber = entities.phoneNumbers.first
        entities.url = entities.urls.first
        entities.urlHost = entities.urlHosts.first

        if entities.time == nil {
            entities.time = firstMatch(
                for: "\\b(?:[01]?\\d|2[0-3]):[0-5]\\d\\b|\\b(?:1[0-2]|0?[1-9])\\s?(?:AM|PM|am|pm)\\b",
                in: text
            )
        }

        if entities.date == nil {
            entities.date = firstMatch(
                for: "\\b\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4}\\b",
                in: text
            )
        }

        return entities
    }

    private func firstMatch(
        for pattern: String,
        in text: String,
        options: NSRegularExpression.Options = []
    ) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return nil
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let matchRange = Range(match.range, in: text) else {
            return nil
        }

        return String(text[matchRange])
    }

    private func allMatches(
        for pattern: String,
        in text: String,
        options: NSRegularExpression.Options = []
    ) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return []
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        var values: [String] = []

        for match in matches {
            guard let matchRange = Range(match.range, in: text) else { continue }
            let value = String(text[matchRange])
            if values.contains(value) == false {
                values.append(value)
            }
        }

        return values
    }
}
