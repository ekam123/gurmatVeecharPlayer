import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject private var audioManager = AudioPlayerManager()
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FavoriteFolderRecord.dateAdded, ascending: false)],
        animation: .default)
    private var favorites: FetchedResults<FavoriteFolderRecord>

    @State private var databaseManager: DatabaseManager?
    @State private var downloadManager = DownloadManager.shared
    @State private var isInitialized = false

    private let rootFolders: [AudioItem] = [
        AudioItem(name: "Gurbani Santhya", type: .folder, url: "/Gurbani_Santhya"),
        AudioItem(name: "Gurbani Ucharan", type: .folder, url: "/Gurbani_Ucharan"),
        AudioItem(name: "Katha", type: .folder, url: "/Katha"),
        AudioItem(name: "Kaveeshri & Dhadi", type: .folder, url: "/Kaveeshri_and_Dhadi"),
        AudioItem(name: "Keertan", type: .folder, url: "/Keertan")
    ]

    var body: some View {
        Group {
            if isInitialized, let dbManager = databaseManager {
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
                    .navigationTitle("Audio")
                    .navigationBarTitleDisplayMode(.large)
                    .navigationDestination(for: AudioItem.self) { item in
                        if item.type == .folder {
                            LazyFolderBrowserView(
                                folderItem: item,
                                audioManager: audioManager,
                                databaseManager: dbManager,
                                downloadManager: downloadManager
                            )
                        } else {
                            PlayerView(
                                audioItem: item,
                                audioManager: audioManager,
                                databaseManager: dbManager
                            )
                        }
                    }
                }
            } else {
                // Initial loading view
                ZStack {
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

                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(AppTheme.primaryBlue)

                        Text("Initializing...")
                            .font(.headline)
                            .foregroundColor(AppTheme.primaryBlue)
                    }
                }
            }
        }
        .onAppear {
            // Initialize database manager synchronously on first appear
            if !isInitialized {
                databaseManager = DatabaseManager(context: viewContext)
                audioManager.setDatabaseManager(databaseManager!)
                isInitialized = true
            }
        }
    }
}

struct FavoriteItemRow: View {
    let favorite: FavoriteFolderRecord

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppTheme.primaryOrange,
                                AppTheme.secondaryOrange
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 3)

                Image(systemName: "heart.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 24, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(favorite.folderName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Favorite Folder")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.primaryBlue.opacity(0.6))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    AppTheme.primaryOrange.opacity(0.6),
                                    AppTheme.lightOrange.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: AppTheme.primaryOrange.opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
