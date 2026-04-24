import SwiftUI

struct RootTabView: View {
    @AppStorage(OnboardingState.hasCompletedKey) private var hasCompletedOnboarding = false
    @AppStorage(OnboardingState.shouldPresentKey) private var shouldPresentOnboarding = false
    @State private var isPresentingOnboarding = false

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
        .onAppear {
            isPresentingOnboarding = !hasCompletedOnboarding || shouldPresentOnboarding
        }
        .onChange(of: shouldPresentOnboarding) { _, newValue in
            if newValue {
                isPresentingOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $isPresentingOnboarding) {
            FirstRunOnboardingView {
                hasCompletedOnboarding = true
                shouldPresentOnboarding = false
                isPresentingOnboarding = false
            }
        }
    }
}
