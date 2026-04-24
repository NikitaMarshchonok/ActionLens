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
                    detail: "Use Import tab or Share Extension from other apps."
                )

                OnboardingStepView(
                    title: "Review",
                    subtitle: "Check extracted text and detected values.",
                    systemImage: "doc.text.magnifyingglass",
                    detail: "Open any item from Inbox to see OCR text and structured details."
                )

                OnboardingStepView(
                    title: "Act",
                    subtitle: "Use suggested actions to complete tasks quickly.",
                    systemImage: "checklist",
                    detail: "Call, email, open links, create reminders/events, or create contacts."
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
