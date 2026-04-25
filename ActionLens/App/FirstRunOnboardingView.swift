import SwiftUI

struct FirstRunOnboardingView: View {
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            TabView {
                OnboardingStepView(
                    title: "Import",
                    subtitle: "Bring in photos, files, or shared content.",
                    systemImage: "square.and.arrow.down",
                    detail: "Use Import to add content, or use Share from other apps."
                )

                OnboardingStepView(
                    title: "Review",
                    subtitle: "Review extracted text and detected details.",
                    systemImage: "doc.text.magnifyingglass",
                    detail: "Open any Inbox item to view details and available actions."
                )

                OnboardingStepView(
                    title: "Act",
                    subtitle: "Use suggested actions to finish tasks faster.",
                    systemImage: "checklist",
                    detail: "Call, email, open links, create reminders or events, and create contacts."
                )
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .navigationTitle("Welcome to ActionLens")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onDone()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    onDone()
                } label: {
                    Text("Get Started")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(.thinMaterial)
            }
        }
    }
}

private struct OnboardingStepView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let detail: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .padding(18)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(Circle())

            Text(title)
                .font(.title3.weight(.semibold))

            Text(subtitle)
                .font(.body)
                .multilineTextAlignment(.center)

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
