import Foundation
import os

struct SharedInboxStore {
    private static let logger = Logger(subsystem: "ActionLens", category: "SharedInboxStore")
    private let appGroupIdentifier: String
    private let queueKey: String

    init(
        appGroupIdentifier: String = SharedContainerConfig.appGroupIdentifier,
        queueKey: String = SharedContainerConfig.queueDefaultsKey
    ) {
        self.appGroupIdentifier = appGroupIdentifier
        self.queueKey = queueKey
    }

    func enqueue(_ payload: SharedInboxPayload) {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        var queue = loadQueue(from: defaults)
        queue.append(payload)
        saveQueue(queue, to: defaults)
    }

    func dequeueAll() -> [SharedInboxPayload] {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return [] }
        let queue = loadQueue(from: defaults)
        saveQueue([], to: defaults)
        return queue
    }

    func pendingPayloads() -> [SharedInboxPayload] {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return [] }
        return loadQueue(from: defaults)
    }

    func removePayloads(withIDs ids: Set<UUID>) {
        guard ids.isEmpty == false, let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        let queue = loadQueue(from: defaults)
        let filteredQueue = queue.filter { ids.contains($0.id) == false }
        saveQueue(filteredQueue, to: defaults)
    }

    func sharedFilesDirectoryURL() -> URL? {
        let fileManager = FileManager.default
        guard let containerURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            return nil
        }

        let directoryURL = containerURL.appendingPathComponent(SharedContainerConfig.sharedFilesDirectory)
        if fileManager.fileExists(atPath: directoryURL.path) == false {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            } catch {
                Self.logger.error("Failed to create shared files directory: \(error.localizedDescription, privacy: .public)")
                return nil
            }
        }

        return directoryURL
    }

    private func loadQueue(from defaults: UserDefaults) -> [SharedInboxPayload] {
        guard let data = defaults.data(forKey: queueKey),
              let queue = try? JSONDecoder().decode([SharedInboxPayload].self, from: data) else {
            return []
        }
        return queue
    }

    private func saveQueue(_ queue: [SharedInboxPayload], to defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(queue) else {
            Self.logger.error("Failed to encode shared inbox payload queue.")
            return
        }
        defaults.set(data, forKey: queueKey)
    }
}
