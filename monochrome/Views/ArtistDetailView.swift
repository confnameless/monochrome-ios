import SwiftUI

struct ArtistDetailView: View {
    let artist: Artist
    @Binding var navigationPath: NavigationPath
    @Environment(AudioPlayerService.self) private var audioPlayer
    @Environment(LibraryManager.self) private var libraryManager
    @State private var artistDetail: ArtistDetail?
    @State private var isLoading = true
    @State private var showAllTracks = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero header
                    artistHeader

                    // Content
                    VStack(alignment: .leading, spacing: 28) {
                        // Shuffle play button
                        if let detail = artistDetail, !detail.topTracks.isEmpty {
                            shuffleButton(tracks: detail.topTracks)
                        }

                        // Popular tracks
                        if let detail = artistDetail, !detail.topTracks.isEmpty {
                            popularTracksSection(tracks: detail.topTracks)
                        }

                        // Albums / Discography
                        if let detail = artistDetail, !detail.albums.isEmpty {
                            discographySection(albums: detail.albums)
                        }

                        Spacer(minLength: 120)
                    }
                    .padding(.top, 16)
                }
            }

            if isLoading {
                ProgressView().tint(Theme.mutedForeground)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(artist.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.foreground)
            }
        }
        .toolbarBackground(Theme.background.opacity(0.8), for: .navigationBar)
        .task { await loadArtist() }
    }

    // MARK: - Hero Header

    private var artistHeader: some View {
        ZStack(alignment: .bottomLeading) {
            // Artist image
            AsyncImage(url: MonochromeAPI().getImageUrl(id: artist.picture, size: 750)) { phase in
                if let image = phase.image {
                    image.resizable()
                         .aspectRatio(contentMode: .fill)
                         .frame(height: 340)
                         .clipped()
                         .overlay(
                            LinearGradient(
                                colors: [.clear, .clear, Theme.background.opacity(0.6), Theme.background],
                                startPoint: .top, endPoint: .bottom
                            )
                         )
                } else {
                    Rectangle().fill(Theme.secondary)
                        .frame(height: 340)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Theme.mutedForeground.opacity(0.3))
                        )
                }
            }
            .frame(height: 340)

            // Name overlay
            VStack(alignment: .leading, spacing: 6) {
                Text(artist.name)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 8, y: 2)

                if let pop = artistDetail?.popularity, pop > 0 {
                    Text("\(pop)% de popularite")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Shuffle Play Button

    @ViewBuilder
    private func shuffleButton(tracks: [Track]) -> some View {
        HStack {
            Button(action: {
                let shuffled = tracks.shuffled()
                if let first = shuffled.first {
                    audioPlayer.play(track: first, queue: Array(shuffled.dropFirst()))
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Lecture aleatoire")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(Theme.primaryForeground)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Theme.primary)
                .clipShape(Capsule())
            }

            Spacer()

            Button(action: {
                if let first = tracks.first {
                    audioPlayer.play(track: first, queue: Array(tracks.dropFirst()))
                }
            }) {
                Image(systemName: "play.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.foreground)
                    .frame(width: 48, height: 48)
                    .background(Theme.secondary)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Popular Tracks

    @ViewBuilder
    private func popularTracksSection(tracks: [Track]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Titres populaires")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.foreground)
                .padding(.horizontal, 16)

            let displayed = showAllTracks ? tracks : Array(tracks.prefix(5))

            ForEach(Array(displayed.enumerated()), id: \.element.id) { index, track in
                let queue = Array(tracks.dropFirst(index + 1))
                TrackRow(
                    track: track,
                    queue: queue,
                    showCover: true,
                    showIndex: index + 1,
                    navigationPath: $navigationPath
                )
            }

            if tracks.count > 5 {
                Button(action: { withAnimation { showAllTracks.toggle() } }) {
                    Text(showAllTracks ? "Afficher moins" : "Voir plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.mutedForeground)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Discography

    @ViewBuilder
    private func discographySection(albums: [Album]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Discographie")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.foreground)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(albums) { album in
                        AlbumCard(album: album)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Load Data

    private func loadArtist() async {
        do {
            artistDetail = try await MonochromeAPI().fetchArtist(id: artist.id)
        } catch {
            print("Error loading artist: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Album Card

struct AlbumCard: View {
    let album: Album

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: MonochromeAPI().getImageUrl(id: album.cover)) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    RoundedRectangle(cornerRadius: 4).fill(Theme.card)
                }
            }
            .frame(width: 150, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            Text(album.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.foreground)
                .lineLimit(1)

            if let year = album.releaseYear {
                Text(year)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.mutedForeground)
            }
        }
        .frame(width: 150)
    }
}
