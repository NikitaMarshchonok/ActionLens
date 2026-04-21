struct SettingsViewModel {
    let title: String

    init(environment: AppEnvironment = .live) {
        title = environment.shellService.appDisplayName
    }
}
