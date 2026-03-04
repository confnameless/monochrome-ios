import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var navigationPath = NavigationPath()
    @State private var playerExpansion: CGFloat = 0
    @State private var dragOffset: CGFloat = 0
    @Environment(AudioPlayerService.self) private var audioPlayer

    private let fullScreenH = UIScreen.main.bounds.height

    var body: some View {
        ZStack {
            if #available(iOS 26.0, *) {
                nativeTabView
            } else {
                legacyTabView
            }

            // Full-screen player overlay
            if audioPlayer.currentTrack != nil && playerExpansion > 0 {
                let effectiveExp = max(0, min(1,
                    playerExpansion - (dragOffset / fullScreenH)
                ))
                let yOffset = (1 - effectiveExp) * fullScreenH

                NowPlayingView(expansion: $playerExpansion, navigationPath: $navigationPath)
                    .offset(y: yOffset)
                    .allowsHitTesting(effectiveExp > 0.3)
                    .gesture(closeDragGesture)
                    .transition(.identity)
                    .ignoresSafeArea()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - iOS 26+ Native Liquid Glass TabView

    @available(iOS 26.0, *)
    private var nativeTabView: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                NavigationStack(path: $navigationPath) {
                    HomeView(navigationPath: $navigationPath)
                        .navigationBarHidden(true)
                        .navigationDestination(for: Artist.self) { artist in
                            ArtistDetailView(artist: artist, navigationPath: $navigationPath)
                        }
                }
            }

            Tab("Library", systemImage: "books.vertical.fill", value: 1) {
                NavigationStack(path: $navigationPath) {
                    LibraryView(navigationPath: $navigationPath)
                        .navigationBarHidden(true)
                        .navigationDestination(for: Artist.self) { artist in
                            ArtistDetailView(artist: artist, navigationPath: $navigationPath)
                        }
                }
            }
        }
        .tabViewBottomAccessory {
            if audioPlayer.currentTrack != nil {
                MiniPlayerView(expansion: $playerExpansion)
                    .opacity(playerExpansion > 0 ? 0 : 1)
                    .allowsHitTesting(playerExpansion == 0)
            }
        }
    }

    // MARK: - Legacy Tab View (iOS < 26)

    private var legacyTabView: some View {
        ZStack(alignment: .bottom) {
            NavigationStack(path: $navigationPath) {
                Group {
                    switch selectedTab {
                    case 0: HomeView(navigationPath: $navigationPath)
                    case 1: LibraryView(navigationPath: $navigationPath)
                    default: HomeView(navigationPath: $navigationPath)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.background)
                .navigationBarHidden(true)
                .navigationDestination(for: Artist.self) { artist in
                    ArtistDetailView(artist: artist, navigationPath: $navigationPath)
                }
            }

            VStack(spacing: 6) {
                if audioPlayer.currentTrack != nil {
                    MiniPlayerView(expansion: $playerExpansion)
                        .opacity(playerExpansion > 0 ? 0 : 1)
                        .allowsHitTesting(playerExpansion == 0)
                }

                HStack(spacing: 0) {
                    TabBarButton(icon: "house.fill", label: "Home", isSelected: selectedTab == 0) { selectedTab = 0 }
                    TabBarButton(icon: "books.vertical.fill", label: "Library", isSelected: selectedTab == 1) { selectedTab = 1 }
                }
                .padding(.top, 10)
                .padding(.bottom, 8)
                .padding(.horizontal, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.horizontal, 40)
            }
            .padding(.bottom, 5)
        }
        .ignoresSafeArea()
    }

    // MARK: - Close drag (drag down from full player)

    private var closeDragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                dragOffset = max(0, value.translation.height)
            }
            .onEnded { value in
                let velocity = value.predictedEndTranslation.height - value.translation.height
                let dragDown = value.translation.height / fullScreenH

                withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                    if dragDown > 0.2 || velocity > 400 {
                        playerExpansion = 0
                    } else {
                        playerExpansion = 1
                    }
                    dragOffset = 0
                }
            }
    }
}

// MARK: - Tab Bar Button

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? Theme.foreground : Theme.mutedForeground)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
        .environment(AudioPlayerService())
        .environment(LibraryManager.shared)
}
