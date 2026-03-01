import SwiftUI

struct LyricsView: View {
    @Environment(AudioPlayerService.self) private var audioPlayer
    
    // In a real app, this would be fetched from MonochromeAPI and parsed into an array of timed lines
    let mockLyrics = [
        "J'me balade dans la ville",
        "Écouteurs branchés, le monde défile",
        "Application monochrome sur fond sombre",
        "La musique m'emmène loin des ombres"
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Paroles - \(audioPlayer.currentTrackTitle)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(0..<mockLyrics.count, id: \.self) { index in
                            Text(mockLyrics[index])
                                .font(.title3)
                                // Mock highlighting the first line to simulate sync
                                .foregroundColor(index == 0 ? .white : .gray)
                                .fontWeight(index == 0 ? .bold : .regular)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    LyricsView()
        .environment(AudioPlayerService())
}
