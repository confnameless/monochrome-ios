import SwiftUI

struct HomeView: View {
    @Environment(AudioPlayerService.self) private var audioPlayer
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    Text("Monochrome iOS")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                    
                    Spacer()
                    
                    if audioPlayer.isPlaying {
                        Text("Playing: \(audioPlayer.currentTrackTitle) by \(audioPlayer.currentArtistName)")
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Button(action: {
                        // Demo play action
                        if let url = URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3") {
                            audioPlayer.play(url: url, title: "Demo Song", artist: "Unknown Artist")
                        }
                    }) {
                        Text(audioPlayer.isPlaying ? "Pause" : "Play Demo Stream")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(AudioPlayerService())
}
