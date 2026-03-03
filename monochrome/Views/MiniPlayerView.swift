import SwiftUI

struct MiniPlayerView: View {
    @Environment(AudioPlayerService.self) private var audioPlayer
    @Environment(LibraryManager.self) private var libraryManager
    @State private var showNowPlaying = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                // Cover art
                AsyncImage(url: audioPlayer.currentCoverUrl) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        RoundedRectangle(cornerRadius: 4).fill(Theme.card)
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 4))

                // Track info
                VStack(alignment: .leading, spacing: 1) {
                    Text(audioPlayer.currentTrackTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.foreground)
                        .lineLimit(1)
                    Text(audioPlayer.currentArtistName)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.mutedForeground)
                        .lineLimit(1)
                }

                Spacer()

                // Like button
                if let track = audioPlayer.currentTrack {
                    Button(action: { libraryManager.toggleFavorite(track: track) }) {
                        Image(systemName: libraryManager.isFavorite(trackId: track.id) ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundColor(libraryManager.isFavorite(trackId: track.id) ? Theme.foreground : Theme.mutedForeground)
                    }
                    .buttonStyle(.plain)
                }

                // Play/pause
                Button(action: { audioPlayer.togglePlayPause() }) {
                    Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.foreground)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Progress bar
            GeometryReader { geo in
                let progress = audioPlayer.duration > 0 ? (audioPlayer.currentTime / audioPlayer.duration) : 0
                ZStack(alignment: .leading) {
                    Rectangle().fill(Theme.border.opacity(0.3))
                    Rectangle().fill(Theme.foreground)
                        .frame(width: max(0, geo.size.width * progress))
                }
            }
            .frame(height: 2)
        }
        .background(Theme.secondary.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .onTapGesture { showNowPlaying = true }
        .fullScreenCover(isPresented: $showNowPlaying) {
            NowPlayingView()
        }
    }
}
