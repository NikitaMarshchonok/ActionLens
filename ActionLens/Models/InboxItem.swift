import Foundation
import SwiftData

@Model
final class InboxItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var sourceType: String
    var createdAt: Date
    var status: String
    var extractedText: String?
    var itemTypeRaw: String?
    var isDemoItem: Bool

    init(
        id: UUID = UUID(),
        title: String,
        sourceType: String,
        createdAt: Date = .now,
        status: String,
        extractedText: String? = nil,
        itemTypeRaw: String? = nil,
        isDemoItem: Bool = false
    ) {
        self.id = id
        self.title = title
        self.sourceType = sourceType
        self.createdAt = createdAt
        self.status = status
        self.extractedText = extractedText
        self.itemTypeRaw = itemTypeRaw
        self.isDemoItem = isDemoItem
    }
}
