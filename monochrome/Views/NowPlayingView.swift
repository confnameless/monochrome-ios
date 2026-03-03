import SwiftUI

struct NowPlayingView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AudioPlayerService.self) private var audioPlayer
    @Environment(LibraryManager.self) private var libraryManager

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Blurred background
                if let coverUrl = audioPlayer.currentCoverUrl {
                    AsyncImage(url: coverUrl) { phase in
                        if let image = phase.image {
                            image.resizable()
                                 .aspectRatio(contentMode: .fill)
                                 .frame(width: geo.size.width, height: geo.size.height)
                                 .clipped()
                                 .blur(radius: 80)
                                 .brightness(-0.4)
                                 .scaleEffect(1.3)
                        } else {
                            Theme.background
                        }
                    }
                    .ignoresSafeArea()
                } else {
                    Theme.background.ignoresSafeArea()
                }

                Color.black.opacity(0.25).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top bar
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }

                        Spacer()

                        VStack(spacing: 2) {
                            Text("LECTURE EN COURS")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(1)
                            if let album = audioPlayer.currentTrack?.album?.title {
                                Text(album)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    Spacer()

                    // Album art
                    AsyncImage(url: audioPlayer.currentCoverUrl) { phase in
                        if let image = phase.image {
                            image.resizable()
                                 .aspectRatio(contentMode: .fit)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.card)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.5), radius: 30, y: 15)
                    .padding(.horizontal, 28)
                    .frame(maxWidth: min(geo.size.width - 56, geo.size.height * 0.42))

                    Spacer().frame(height: 32)

                    // Track info + like
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(audioPlayer.currentTrackTitle)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text(audioPlayer.currentArtistName)
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                        }

                        Spacer()

                        if let track = audioPlayer.currentTrack {
                            Button(action: { libraryManager.toggleFavorite(track: track) }) {
                                Image(systemName: libraryManager.isFavorite(trackId: track.id) ? "heart.fill" : "heart")
                                    .font(.system(size: 22))
                                    .foregroundColor(libraryManager.isFavorite(trackId: track.id) ? .white : .white.opacity(0.5))
                            }
                        }
                    }
                    .padding(.horizontal, 28)

                    Spacer().frame(height: 20)

                    // Progress slider
                    VStack(spacing: 6) {
                        Slider(
                            value: Binding(
                                get: { audioPlayer.currentTime },
                                set: { audioPlayer.seek(to: $0) }
                            ),
                            in: 0...(audioPlayer.duration > 0 ? audioPlayer.duration : 1)
                        )
                        .tint(.white)

                        HStack {
                            Text(formatTime(audioPlayer.currentTime))
                            Spacer()
                            Text("-" + formatTime(max(0, audioPlayer.duration - audioPlayer.currentTime)))
                        }
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 28)

                    Spacer().frame(height: 20)

                    // Playback controls
                    HStack(spacing: 0) {
                        Spacer()

                        Button(action: { audioPlayer.previousTrack() }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 28))
                                .foregroundColor(audioPlayer.hasPreviousTrack ? .white : .white.opacity(0.3))
                        }
                        .frame(width: 60)

                        Spacer()

                        Button(action: { audioPlayer.togglePlayPause() }) {
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 64, height: 64)
                                Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(.black)
                                    .offset(x: audioPlayer.isPlaying ? 0 : 2)
                            }
                        }

                        Spacer()

                        Button(action: { audioPlayer.nextTrack() }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 28))
                                .foregroundColor(audioPlayer.hasNextTrack ? .white : .white.opacity(0.3))
                        }
                        .frame(width: 60)

                        Spacer()
                    }

                    Spacer()

                    // Bottom row (queue indicator)
                    HStack {
                        Spacer()
                        if !audioPlayer.queuedTracks.isEmpty {
                            Text("\(audioPlayer.queuedTracks.count) titre\(audioPlayer.queuedTracks.count > 1 ? "s" : "") dans la file")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Spacer()
                    }
                    .padding(.bottom, geo.safeAreaInsets.bottom > 0 ? 8 : 20)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 120 { dismiss() }
                }
        )
    }

    private func formatTime(_ time: TimeInterval) -> String {
        guard time > 0 && !time.isNaN else { return "0:00" }
        let m = Int(time) / 60
        let s = Int(time) % 60
        return String(format: "%d:%02d", m, s)
    }
}
