import SwiftUI

struct SettingsView: View {
    private let viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Text("\(viewModel.title) Settings")
                .navigationTitle("Settings")
        }
    }
}
