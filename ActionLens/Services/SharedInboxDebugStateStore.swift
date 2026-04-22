import Foundation

struct SharedInboxDebugStateStore {
    private let defaults: UserDefaults
    private let reportKey = "sharedInbox.lastIngestionReport.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func saveLastReport(_ report: SharedInboxIngestionReport) {
        guard let data = try? JSONEncoder().encode(report) else { return }
        defaults.set(data, forKey: reportKey)
    }

    func loadLastReport() -> SharedInboxIngestionReport? {
        guard let data = defaults.data(forKey: reportKey),
              let report = try? JSONDecoder().decode(SharedInboxIngestionReport.self, from: data) else {
            return nil
        }
        return report
    }
}
