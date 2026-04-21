import Foundation

struct ExtractedEntities {
    var date: String?
    var time: String?
    var amount: String?
    var email: String?
    var phoneNumber: String?
    var url: String?
    var detectedDate: Date?

    var isEmpty: Bool {
        date == nil
            && time == nil
            && amount == nil
            && email == nil
            && phoneNumber == nil
            && url == nil
    }
}

protocol EntityExtractionServicing {
    func extractEntities(from text: String) -> ExtractedEntities
}

struct LocalEntityExtractionService: EntityExtractionServicing {
    func extractEntities(from text: String) -> ExtractedEntities {
        var entities = ExtractedEntities()

        entities.email = firstMatch(
            for: "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}",
            in: text,
            options: [.caseInsensitive]
        )

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
                if entities.phoneNumber == nil, let phoneNumber = match.phoneNumber {
                    entities.phoneNumber = phoneNumber
                }

                if entities.url == nil, let url = match.url, url.scheme != "mailto" {
                    entities.url = url.absoluteString
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
}
