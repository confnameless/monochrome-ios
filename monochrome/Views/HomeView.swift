import SwiftUI

struct HomeView: View {
    @Binding var navigationPath: NavigationPath
    @Environment(AudioPlayerService.self) private var audioPlayer
    @State private var editorPicks: [EditorPick] = []
    @State private var isLoading = true

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Bonjour" }
        if hour < 18 { return "Bon apres-midi" }
        return "Bonsoir"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Greeting header (Spotify style)
                Text(greeting)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Theme.foreground)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // Editor's Picks section
                if isLoading {
                    HStack { Spacer(); ProgressView().tint(Theme.mutedForeground); Spacer() }
                        .padding(.vertical, 60)
                } else if !editorPicks.isEmpty {
                    // Quick picks grid (2 columns like Spotify)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selection de l'editeur")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Theme.foreground)
                            .padding(.horizontal, 16)

                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 8) {
                            ForEach(editorPicks.prefix(6)) { pick in
                                EditorPickCompactCard(pick: pick)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Full cards carousel
                    if editorPicks.count > 6 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("A decouvrir")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Theme.foreground)
                                .padding(.horizontal, 16)

                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 14) {
                                    ForEach(editorPicks.dropFirst(6)) { pick in
                                        EditorPickCard(pick: pick)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }

                Spacer(minLength: 100)
            }
        }
        .background(Theme.background)
        .task {
            do {
                editorPicks = try await MonochromeAPI().fetchEditorsPicks()
            } catch {
                print("Error fetching editor picks: \(error)")
            }
            isLoading = false
        }
    }
}

// MARK: - Compact Card (2-col grid, Spotify style)

struct EditorPickCompactCard: View {
    let pick: EditorPick

    var body: some View {
        HStack(spacing: 0) {
            AsyncImage(url: MonochromeAPI().getImageUrl(id: pick.cover)) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Rectangle().fill(Theme.card)
                }
            }
            .frame(width: 56, height: 56)
            .clipped()

            Text(pick.title ?? "Unknown")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.foreground)
                .lineLimit(2)
                .padding(.horizontal, 10)

            Spacer()
        }
        .frame(height: 56)
        .background(Theme.secondary.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Full Card (horizontal scroll)

struct EditorPickCard: View {
    let pick: EditorPick

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: MonochromeAPI().getImageUrl(id: pick.cover)) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    RoundedRectangle(cornerRadius: 4).fill(Theme.card)
                        .overlay(ProgressView().tint(Theme.mutedForeground))
                }
            }
            .frame(width: 150, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            Text(pick.title ?? "Unknown")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.foreground)
                .lineLimit(1)

            Text(pick.artist?.name ?? "")
                .font(.system(size: 11))
                .foregroundColor(Theme.mutedForeground)
                .lineLimit(1)
        }
        .frame(width: 150)
    }
}

#Preview {
    NavigationStack {
        HomeView(navigationPath: .constant(NavigationPath()))
    }
    .environment(AudioPlayerService())
    .environment(LibraryManager.shared)
}
