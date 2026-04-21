import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            InboxView()
                .tabItem {
                    Label("Inbox", systemImage: "tray")
                }

            ImportView()
                .tabItem {
                    Label("Import", systemImage: "square.and.arrow.down")
                }

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
