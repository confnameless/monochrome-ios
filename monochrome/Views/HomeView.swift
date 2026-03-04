import SwiftUI

struct HomeView: View {
    @Binding var navigationPath: NavigationPath
    @Environment(AudioPlayerService.self) private var audioPlayer
    @Environment(LibraryManager.self) private var libraryManager

    @State private var searchResults: [Track] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var lastQuery = ""

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 18 { return "Good afternoon" }
        return "Good evening"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar (isolated view — typing won't re-render home content)
            SearchBar(
                onSearch: { query in
                    lastQuery = query
                    performSearch(query)
                },
                onClear: {
                    searchResults = []
                    hasSearched = false
                    lastQuery = ""
                }
            )

            if hasSearched {
                searchContent
            } else {
                homeContent
            }
        }
        .background(Theme.background)
    }

    // MARK: - Search Content

    @ViewBuilder
    private var searchContent: some View {
        if isSearching {
            Spacer()
            ProgressView().tint(Theme.mutedForeground)
            Spacer()
        } else if !searchResults.isEmpty {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, track in
                        let queue = Array(searchResults.dropFirst(index + 1))
                        TrackRow(track: track, queue: queue, showCover: true, navigationPath: $navigationPath)
                    }
                }
                .padding(.bottom, 120)
            }
        } else if hasSearched {
            Spacer()
            VStack(spacing: 10) {
                Text("No results for")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.mutedForeground)
                Text("\"\(lastQuery)\"")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.foreground)
            }
            Spacer()
        }
    }

    // MARK: - Home Content

    private var homeContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text(greeting)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Theme.foreground)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                if !audioPlayer.playHistory.isEmpty || audioPlayer.currentTrack != nil {
                    recentlyPlayed
                }

                if !libraryManager.favoriteTracks.isEmpty {
                    favoritesSection
                }

                if audioPlayer.playHistory.isEmpty && audioPlayer.currentTrack == nil && libraryManager.favoriteTracks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note")
                            .font(.system(size: 52, weight: .light))
                            .foregroundColor(Theme.mutedForeground.opacity(0.3))
                        Text("Search for a track to get started")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.mutedForeground)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                }

                Spacer(minLength: 100)
            }
        }
    }

    // MARK: - Recently Played

    private var recentlyPlayed: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently played")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.foreground)
                .padding(.horizontal, 16)

            // Compact grid (2 columns, Spotify style)
            let recentTracks = recentTracksList
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(recentTracks.prefix(6)) { track in
                    RecentTrackCard(track: track) {
                        audioPlayer.play(track: track)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var recentTracksList: [Track] {
        var tracks: [Track] = []
        // Current track first
        if let current = audioPlayer.currentTrack {
            tracks.append(current)
        }
        // Then history (most recent first), deduplicated
        for track in audioPlayer.playHistory.reversed() {
            if !tracks.contains(where: { $0.id == track.id }) {
                tracks.append(track)
            }
        }
        return tracks
    }

    // MARK: - Favorites

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your favorites")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.foreground)

                Spacer()

                Text("\(libraryManager.favoriteTracks.count) track\(libraryManager.favoriteTracks.count > 1 ? "s" : "")")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.mutedForeground)
            }
            .padding(.horizontal, 16)

            LazyVStack(spacing: 0) {
                ForEach(Array(libraryManager.favoriteTracks.prefix(5).enumerated()), id: \.element.id) { index, track in
                    let queue = Array(libraryManager.favoriteTracks.dropFirst(index + 1))
                    TrackRow(track: track, queue: queue, showCover: true, navigationPath: $navigationPath)
                }
            }
        }
    }

    // MARK: - Search

    private func performSearch(_ query: String) {
        guard !query.isEmpty else { return }
        isSearching = true
        hasSearched = true

        Task {
            do { searchResults = try await MonochromeAPI().searchTracks(query: query) }
            catch { print("Search error: \(error)") }
            isSearching = false
        }
    }
}

// MARK: - Search Bar (isolated to prevent re-renders)

private struct SearchBar: View {
    let onSearch: (String) -> Void
    let onClear: () -> Void
    @State private var text = ""

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(Theme.mutedForeground)

            TextField("What do you want to listen to?", text: $text)
                .font(.system(size: 16))
                .foregroundColor(Theme.foreground)
                .autocorrectionDisabled()
                .onSubmit { onSearch(text) }

            if !text.isEmpty {
                Button(action: { text = ""; onClear() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.mutedForeground)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

// MARK: - Recent Track Card (compact, 2-col grid)

struct RecentTrackCard: View {
    let track: Track
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                AsyncImage(url: MonochromeAPI().getImageUrl(id: track.album?.cover)) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle().fill(Theme.card)
                    }
                }
                .frame(width: 56, height: 56)
                .clipped()

                Text(track.title)
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
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        HomeView(navigationPath: .constant(NavigationPath()))
    }
    .environment(AudioPlayerService())
    .environment(LibraryManager.shared)
}
