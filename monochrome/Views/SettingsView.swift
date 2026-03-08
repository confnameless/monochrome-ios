import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Playback
                    SettingsSection(title: "Playback") {
                        SettingsRow(icon: "waveform", title: "Audio Quality", value: "High")
                        SettingsRow(icon: "antenna.radiowaves.left.and.right", title: "Streaming", value: "Wi-Fi + Cellular")
                        SettingsRow(icon: "speaker.wave.2.fill", title: "Normalisation", value: "On")
                    }

                    // MARK: - Storage
                    SettingsSection(title: "Storage") {
                        SettingsRow(icon: "internaldrive.fill", title: "Cache Size", value: "0 MB")
                        SettingsRow(icon: "trash.fill", title: "Clear Cache", isAction: true)
                    }

                    // MARK: - Appearance
                    SettingsSection(title: "Appearance") {
                        SettingsRow(icon: "paintbrush.fill", title: "Theme", value: "Dark")
                        SettingsRow(icon: "textformat.size", title: "Text Size", value: "Default")
                    }

                    // MARK: - About
                    SettingsSection(title: "About") {
                        SettingsRow(icon: "info.circle.fill", title: "Version", value: appVersion)
                        SettingsRow(icon: "doc.text.fill", title: "Terms of Service")
                        SettingsRow(icon: "hand.raised.fill", title: "Privacy Policy")
                        SettingsRow(icon: "envelope.fill", title: "Contact Us")
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 8)
            }
            .background(Theme.background)
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.foreground)
                            .frame(width: 30, height: 30)
                            .background(Theme.secondary)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Settings Section

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.mutedForeground)
                .tracking(0.8)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                content
            }
            .background(Theme.secondary.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLg))
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Settings Row

private struct SettingsRow: View {
    let icon: String
    let title: String
    var value: String? = nil
    var isAction: Bool = false

    var body: some View {
        Button {
            // Not implemented yet
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(isAction ? .red : Theme.foreground)
                    .frame(width: 22)

                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(isAction ? .red : Theme.foreground)

                Spacer()

                if let value {
                    Text(value)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.mutedForeground)
                }

                if !isAction {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.mutedForeground.opacity(0.5))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
        .presentationDetents([.medium, .large])
}
