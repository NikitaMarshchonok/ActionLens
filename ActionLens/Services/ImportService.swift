import Foundation

protocol ImportServicing {
    func makeImportedItem(
        title: String,
        sourceType: String,
        extractedText: String?,
        itemTypeRaw: String?
    ) -> InboxItem
}

struct ImportService: ImportServicing {
    func makeImportedItem(
        title: String,
        sourceType: String,
        extractedText: String? = nil,
        itemTypeRaw: String? = nil
    ) -> InboxItem {
        return InboxItem(
            title: title,
            sourceType: sourceType,
            createdAt: .now,
            status: "new",
            extractedText: extractedText,
            itemTypeRaw: itemTypeRaw
        )
    }
}
