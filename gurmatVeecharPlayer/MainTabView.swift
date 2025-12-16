import SwiftUI

struct MainTabView: View {
    @ObservedObject var audioManager: AudioPlayerManager
    let databaseManager: DatabaseManager
    let downloadManager: DownloadManager
    @StateObject private var navigationState = NavigationState()
    @State private var showPlayerView = false

    var body: some View {
        VStack(spacing: 0) {
            // Now Playing Bar at the top - hide when showing full player
            if !navigationState.isShowingFullPlayer {
                NowPlayingBar(audioManager: audioManager) {
                    // When tapped, show player view
                    showPlayerView = true
                }
            }

            // Tab View
            TabView {
                // Browse Tab
                BrowseView(
                    audioManager: audioManager,
                    databaseManager: databaseManager,
                    downloadManager: downloadManager
                )
                .tabItem {
                    Label("Browse", systemImage: "folder.fill")
                }
                .environmentObject(navigationState)

                // Favorites Tab
                FavoritesView(
                    audioManager: audioManager,
                    databaseManager: databaseManager,
                    downloadManager: downloadManager
                )
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
                .environmentObject(navigationState)

                // Downloads Tab
                DownloadsView(
                    audioManager: audioManager,
                    databaseManager: databaseManager
                )
                .tabItem {
                    Label("Downloads", systemImage: "arrow.down.circle.fill")
                }
                .environmentObject(navigationState)
            }
            .accentColor(AppTheme.primaryOrange)
        }
        .fullScreenCover(isPresented: $showPlayerView) {
            if let url = audioManager.currentTrackURL {
                PlayerView(
                    audioItem: AudioItem(
                        name: audioManager.currentTrackTitle,
                        type: .audio,
                        url: url
                    ),
                    audioManager: audioManager,
                    databaseManager: databaseManager
                )
                .environmentObject(navigationState)
            }
        }
    }
}
