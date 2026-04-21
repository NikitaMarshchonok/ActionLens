import Foundation

enum ExtensionSharedPayloadType: String, Codable {
    case text
    case url
    case image
    case file
}

struct ExtensionSharedInboxPayload: Codable {
    let id: UUID
    let type: ExtensionSharedPayloadType
    let text: String?
    let urlString: String?
    let fileName: String?
    let relativeFilePath: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        type: ExtensionSharedPayloadType,
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

enum ExtensionSharedContainerConfig {
    static let appGroupIdentifier = "group.com.nikita.project.ActionLens"
    static let queueDefaultsKey = "sharedInboxPayloadQueue.v1"
    static let sharedFilesDirectory = "SharedInboxFiles"
}

struct ExtensionSharedInboxStore {
    private let appGroupIdentifier: String
    private let queueKey: String

    init(
        appGroupIdentifier: String = ExtensionSharedContainerConfig.appGroupIdentifier,
        queueKey: String = ExtensionSharedContainerConfig.queueDefaultsKey
    ) {
        self.appGroupIdentifier = appGroupIdentifier
        self.queueKey = queueKey
    }

    func enqueue(_ payload: ExtensionSharedInboxPayload) {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        var queue = loadQueue(from: defaults)
        queue.append(payload)
        saveQueue(queue, to: defaults)
    }

    func sharedFilesDirectoryURL() -> URL? {
        let fileManager = FileManager.default
        guard let containerURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            return nil
        }

        let directoryURL = containerURL.appendingPathComponent(ExtensionSharedContainerConfig.sharedFilesDirectory)
        if fileManager.fileExists(atPath: directoryURL.path) == false {
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        return directoryURL
    }

    private func loadQueue(from defaults: UserDefaults) -> [ExtensionSharedInboxPayload] {
        guard let data = defaults.data(forKey: queueKey),
              let queue = try? JSONDecoder().decode([ExtensionSharedInboxPayload].self, from: data) else {
            return []
        }
        return queue
    }

    private func saveQueue(_ queue: [ExtensionSharedInboxPayload], to defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(queue) else { return }
        defaults.set(data, forKey: queueKey)
    }
}
