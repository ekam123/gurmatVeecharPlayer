import SwiftUI
import CoreData

struct BrowseView: View {
    @ObservedObject var audioManager: AudioPlayerManager
    let databaseManager: DatabaseManager
    let downloadManager: DownloadManager
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var navigationState: NavigationState
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FavoriteFolderRecord.dateAdded, ascending: false)],
        animation: .default)
    private var favorites: FetchedResults<FavoriteFolderRecord>

    private let rootFolders: [AudioItem] = [
        AudioItem(name: "Gurbani Santhya", type: .folder, url: "/Gurbani_Santhya"),
        AudioItem(name: "Gurbani Ucharan", type: .folder, url: "/Gurbani_Ucharan"),
        AudioItem(name: "Katha", type: .folder, url: "/Katha"),
        AudioItem(name: "Kaveeshri & Dhadi", type: .folder, url: "/Kaveeshri_and_Dhadi"),
        AudioItem(name: "Keertan", type: .folder, url: "/Keertan")
    ]

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

                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Favorites Section (only show if there are favorites)
                        if !favorites.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(AppTheme.primaryOrange)
                                    Text("Favorites")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }
                                .padding(.horizontal)

                                ForEach(favorites.prefix(3)) { favorite in
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
                            .padding(.vertical)

                            Divider()
                                .padding()
                        }

                        // Root Folders Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Categories")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            ForEach(rootFolders) { item in
                                NavigationLink(value: item) {
                                    ItemRow(item: item)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Browse")
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
                        databaseManager: databaseManager,
                        playlist: item.playlist,
                        trackIndex: item.trackIndex
                    )
                    .environmentObject(navigationState)
                }
            }
        }
    }
}
