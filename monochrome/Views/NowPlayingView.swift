import SwiftUI

struct NowPlayingView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AudioPlayerService.self) private var audioPlayer
    
    var body: some View {
        ZStack {
            // Background blur matching --cover-filter: blur(50px) brightness(0.4)
            if let coverUrl = audioPlayer.currentCoverUrl {
                AsyncImage(url: coverUrl) { phase in
                    if let image = phase.image {
                        image.resizable()
                             .aspectRatio(contentMode: .fill)
                             .blur(radius: 50)
                             .overlay(Color.black.opacity(0.6))
                    } else {
                        Theme.background
                    }
                }
                .ignoresSafeArea()
            } else {
                Theme.background.ignoresSafeArea()
            }
            
            VStack {
                // Handle
                Capsule()
                    .fill(Color.gray)
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                
                Spacer()
                
                // Big Cover
                AsyncImage(url: audioPlayer.currentCoverUrl) { phase in
                    if let image = phase.image {
                        image.resizable()
                             .aspectRatio(1.0, contentMode: .fit)
                    } else {
                        Rectangle().fill(Theme.card)
                    }
                }
                .cornerRadius(Theme.radiusLg)
                .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                .padding(32)
                
                // Track Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(audioPlayer.currentTrackTitle)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.foreground)
                        .lineLimit(1)
                    Text(audioPlayer.currentArtistName)
                        .font(.title3)
                        .foregroundColor(Theme.mutedForeground)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Controls
                HStack(spacing: 40) {
                    Button(action: {
                        // Prev logic
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        audioPlayer.togglePlayPause()
                    }) {
                        Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        // Next logic
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 64)
            }
        }
    }
}
