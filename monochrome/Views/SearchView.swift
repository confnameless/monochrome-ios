import SwiftUI

struct SearchView: View {
    @Environment(AudioPlayerService.self) private var audioPlayer
    @State private var searchText = ""
    @State private var searchResults: [Track] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Input
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Theme.mutedForeground)
                        TextField("Rechercher des titres, albums, artistes...", text: $searchText)
                            .foregroundColor(Theme.foreground)
                            .onSubmit {
                                performSearch()
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                searchResults = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Theme.mutedForeground)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Theme.input)
                    .cornerRadius(Theme.radiusMd)
                    .padding(16)
                    
                    if isSearching {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.primary))
                            .padding()
                    }
                    
                    if !searchResults.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(searchResults) { track in
                                    TrackRow(track: track)
                                }
                            }
                            .padding(.horizontal, 16)
                            // Add extra padding at bottom to clear the mini player
                            .padding(.bottom, 80)
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Recherche")
            .navigationBarHidden(true)
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        isSearching = true
        
        Task {
            do {
                searchResults = try await MonochromeAPI().searchTracks(query: searchText)
            } catch {
                // TODO: Handle error state in UI
            }
            isSearching = false
        }
    }
}

struct TrackRow: View {
    let track: Track
    @Environment(AudioPlayerService.self) private var audioPlayer
    
    var body: some View {
        Button(action: {
            Task {
                if let streamUrlStr = try? await MonochromeAPI().fetchStreamUrl(trackId: track.id),
                   let url = URL(string: streamUrlStr) {
                    await MainActor.run {
                        audioPlayer.play(
                            url: url,
                            title: track.title,
                            artist: track.artist?.name ?? "Unknown",
                            coverUrl: MonochromeAPI().getImageUrl(id: track.album?.cover)
                        )
                    }
                }
            }
        }) {
            HStack(spacing: 12) {
                AsyncImage(url: MonochromeAPI().getImageUrl(id: track.album?.cover)) { phase in
                    if let image = phase.image {
                        image.resizable()
                             .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle().fill(Theme.card)
                    }
                }
                .frame(width: 48, height: 48)
                .cornerRadius(Theme.radiusSm)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .foregroundColor(Theme.foreground)
                        .font(.system(size: 16, weight: .medium))
                        .lineLimit(1)
                    Text(track.artist?.name ?? "Unknown Artist")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.mutedForeground)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "play.circle")
                    .foregroundColor(Theme.mutedForeground)
                    .font(.title3)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SearchView()
        .environment(AudioPlayerService())
}
