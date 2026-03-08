import SwiftUI

struct TrackRow: View {
    let track: Track
    let queue: [Track]
    var previousTracks: [Track] = []
    var showCover: Bool = true
    var showIndex: Int? = nil
    @Binding var navigationPath: NavigationPath
    @Environment(AudioPlayerService.self) private var audioPlayer
    @Environment(LibraryManager.self) private var libraryManager
    @State private var showOptions = false
    @State private var confirmationMessage: String? = nil
    
    private var isCurrentTrack: Bool {
        audioPlayer.currentTrack?.id == track.id
    }

    var body: some View {
        HStack(spacing: 12) {
            // Index or cover
            if let index = showIndex {
                Text("\(index)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isCurrentTrack ? Theme.highlight : Theme.mutedForeground)
                    .frame(width: 28, alignment: .center)
            } else if showCover {
                AsyncImage(url: MonochromeAPI().getImageUrl(id: track.album?.cover)) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        RoundedRectangle(cornerRadius: 4).fill(Theme.card)
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            // Track info
            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(isCurrentTrack ? Theme.highlight : Theme.foreground)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if isCurrentTrack && audioPlayer.isPlaying {
                        Image(systemName: "waveform")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.highlight)
                            .symbolEffect(.variableColor.iterative, isActive: true)
                    }
                    Text(track.artist?.name ?? "Unknown")
                }
                .font(.system(size: 13))
                .foregroundColor(Theme.mutedForeground)
                .lineLimit(1)
            }

            Spacer()

            // Feedback or Context menu button
            if let message = confirmationMessage {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                    Text(message)
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(message.contains("Queue") ? Color.green : Color.blue)
                .clipShape(Capsule())
                .transition(.scale.combined(with: .opacity))
            } else {
                Button(action: { showOptions = true }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.mutedForeground)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Theme.background)
        .contentShape(Rectangle())
        .onTapGesture {
            audioPlayer.play(track: track, queue: queue, previousTracks: previousTracks)
        }
        .onLongPressGesture {
            showOptions = true
        }
        .swipeActions(edge: .leading) {
            Button {
                executeAction(type: "next")
            } label: {
                Label("Play Next", systemImage: "text.insert")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .trailing) {
            Button {
                executeAction(type: "queue")
            } label: {
                Label("Add to Queue", systemImage: "text.append")
            }
            .tint(.green)
        }
        .sheet(isPresented: $showOptions) {
            TrackOptionsSheet(
                track: track,
                queue: queue,
                navigationPath: $navigationPath,
                isPresented: $showOptions
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(Theme.card)
        }
    }

    private func executeAction(type: String) {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Perform logic
        if type == "next" {
            audioPlayer.playNext(track: track)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                confirmationMessage = "Next"
            }
        } else {
            audioPlayer.addToQueue(track: track)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                confirmationMessage = "Added"
            }
        }
        
        // Clear feedback after 1.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.2)) {
                confirmationMessage = nil
            }
        }
    }
}

struct TrackOptionsSheet: View {
    let track: Track
    let queue: [Track]
    @Binding var navigationPath: NavigationPath
    @Binding var isPresented: Bool
    @Environment(AudioPlayerService.self) private var audioPlayer
    @Environment(LibraryManager.self) private var libraryManager

    var body: some View {
        VStack(spacing: 0) {
            // Track header
            HStack(spacing: 14) {
                AsyncImage(url: MonochromeAPI().getImageUrl(id: track.album?.cover)) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        RoundedRectangle(cornerRadius: 6).fill(Theme.secondary)
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.foreground)
                        .lineLimit(1)
                    Text(track.artist?.name ?? "Unknown")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.mutedForeground)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider().overlay(Theme.border)

            // Options
            ScrollView {
                VStack(spacing: 0) {
                    // Like
                    OptionRow(
                        icon: libraryManager.isFavorite(trackId: track.id) ? "heart.fill" : "heart",
                        label: libraryManager.isFavorite(trackId: track.id) ? "Remove from favorites" : "Add to favorites",
                        iconColor: libraryManager.isFavorite(trackId: track.id) ? Theme.foreground : Theme.mutedForeground
                    ) {
                        libraryManager.toggleFavorite(track: track)
                    }

                    // Play next
                    OptionRow(icon: "text.line.first.and.arrowtriangle.forward", label: "Play next") {
                        audioPlayer.playNext(track: track)
                        isPresented = false
                    }

                    // Add to queue
                    OptionRow(icon: "text.line.last.and.arrowtriangle.forward", label: "Add to queue") {
                        audioPlayer.addToQueue(track: track)
                        isPresented = false
                    }

                    // Go to artist
                    if let artist = track.artist {
                        OptionRow(icon: "person.fill", label: "Go to artist") {
                            isPresented = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                navigationPath.append(artist)
                            }
                        }
                    }

                    // Go to album
                    if let album = track.album {
                        OptionRow(icon: "square.stack", label: "Go to album") {
                            isPresented = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                navigationPath.append(album)
                            }
                        }
                    }

                    // Share
                    OptionRow(icon: "square.and.arrow.up", label: "Share") {
                        isPresented = false
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

struct OptionRow: View {
    let icon: String
    let label: String
    var iconColor: Color = Theme.foreground
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 28)

                Text(label)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.foreground)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
