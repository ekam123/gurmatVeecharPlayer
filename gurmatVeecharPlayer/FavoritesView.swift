import SwiftUI
import CoreData

struct FavoritesView: View {
    @ObservedObject var audioManager: AudioPlayerManager
    let databaseManager: DatabaseManager
    let downloadManager: DownloadManager
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var navigationState: NavigationState
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FavoriteFolderRecord.dateAdded, ascending: false)],
        animation: .default)
    private var favorites: FetchedResults<FavoriteFolderRecord>

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppTheme.primaryBlue.opacity(0.15),
                        AppTheme.secondaryBlue.opacity(0.1),
                        AppTheme.primaryOrange.opacity(0.08)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if favorites.isEmpty {
                    // Empty state
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            AppTheme.primaryOrange.opacity(0.3),
                                            AppTheme.lightOrange.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .blur(radius: 15)

                            Image(systemName: "heart.slash")
                                .font(.system(size: 50))
                                .foregroundColor(AppTheme.primaryOrange)
                        }

                        VStack(spacing: 12) {
                            Text("No Favorites")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text("Browse folders and tap the heart icon to add favorites")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                    }
                    .padding(40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(favorites) { favorite in
                                NavigationLink(value: AudioItem(
                                    name: favorite.folderName,
                                    type: .folder,
                                    url: favorite.folderPath
                                )) {
                                    FavoriteItemRow(favorite: favorite)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: AudioItem.self) { item in
                if item.type == .folder {
                    LazyFolderBrowserView(
                        folderItem: item,
                        audioManager: audioManager,
                        databaseManager: databaseManager,
                        downloadManager: downloadManager
                    )
                    .environmentObject(navigationState)
                } else {
                    PlayerView(
                        audioItem: item,
                        audioManager: audioManager,
                        databaseManager: databaseManager
                    )
                    .environmentObject(navigationState)
                }
            }
        }
    }
}
