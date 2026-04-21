protocol AppShellServicing {
    var appDisplayName: String { get }
}

struct AppShellService: AppShellServicing {
    let appDisplayName = "ActionLens"
}
