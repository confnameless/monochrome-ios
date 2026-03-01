import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 1
    @Environment(AudioPlayerService.self) private var audioPlayer
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Accueil", systemImage: "house.fill")
                    }
                    .tag(0)
                
                SearchView()
                    .tabItem {
                        Label("Recherche", systemImage: "magnifyingglass")
                    }
                    .tag(1)
                
                LibraryView()
                    .tabItem {
                        Label("Bibliothèque", systemImage: "play.square.stack.fill")
                    }
                    .tag(2)
            }
            .accentColor(.white)
            
            // Mini Player Overlaid on top of tabs
            if audioPlayer.isPlaying || audioPlayer.player != nil {
                MiniPlayerView()
                    .padding(.bottom, 50) // Adjust based on TabBar safe area
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
        .environment(AudioPlayerService())
}
