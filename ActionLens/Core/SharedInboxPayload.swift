import Foundation

enum SharedPayloadType: String, Codable {
    case text
    case url
    case image
    case file
}

struct SharedInboxPayload: Codable, Identifiable {
    let id: UUID
    let type: SharedPayloadType
    let text: String?
    let urlString: String?
    let fileName: String?
    let relativeFilePath: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        type: SharedPayloadType,
        text: String? = nil,
        urlString: String? = nil,
        fileName: String? = nil,
        relativeFilePath: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.urlString = urlString
        self.fileName = fileName
        self.relativeFilePath = relativeFilePath
        self.createdAt = createdAt
    }
}

enum SharedContainerConfig {
    static let appGroupIdentifier = "group.com.nikita.project.ActionLens"
    static let queueDefaultsKey = "sharedInboxPayloadQueue.v1"
    static let sharedFilesDirectory = "SharedInboxFiles"
}
