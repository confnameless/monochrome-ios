import SwiftUI

struct MiniPlayerView: View {
    @Environment(AudioPlayerService.self) private var audioPlayer
    @State private var showNowPlaying = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                AsyncImage(url: audioPlayer.currentCoverUrl) { phase in
                    if let image = phase.image {
                        image.resizable()
                             .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle().fill(Theme.card)
                    }
                }
                .frame(width: 48, height: 48)
                .cornerRadius(Theme.radiusSm)
                .padding(.leading, 8)
                
                VStack(alignment: .leading) {
                    Text(audioPlayer.currentTrackTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(audioPlayer.currentArtistName)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                .padding(.leading, 8)
                
                Spacer()
                
                Button(action: {
                    audioPlayer.togglePlayPause()
                }) {
                    Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .padding(.trailing, 16)
            }
            .frame(height: 64)
            .background(Theme.secondary.opacity(0.95))
            .cornerRadius(Theme.radiusMd)
            .padding(.horizontal, 8)
            .onTapGesture {
                showNowPlaying = true
            }
            
            // Progress Bar Mini
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.white)
                    .frame(width: geometry.size.width * 0.3, height: 2)
            }
            .frame(height: 2)
            .padding(.horizontal, 12)
            .offset(y: -2)
        }
        .sheet(isPresented: $showNowPlaying) {
            NowPlayingView()
        }
    }
}
