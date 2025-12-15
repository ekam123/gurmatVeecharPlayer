import SwiftUI
import CoreData

struct FolderBrowserView: View {
    let items: [AudioItem]
    let title: String
    let folderPath: String?
    @ObservedObject var audioManager: AudioPlayerManager
    let databaseManager: DatabaseManager
    let downloadManager: DownloadManager

    @State private var isLoading = false
    @State private var isFavorite = false

    var body: some View {
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
                LazyVStack(spacing: 12) {
                    ForEach(items) { item in
                        if item.type == .folder {
                            NavigationLink(value: item) {
                                ItemRow(item: item)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            AudioItemRowWithDownload(
                                item: item,
                                audioManager: audioManager,
                                databaseManager: databaseManager,
                                downloadManager: downloadManager
                            )
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if folderPath != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        toggleFavorite()
                    }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? AppTheme.primaryOrange : .gray)
                            .font(.system(size: 20))
                    }
                }
            }
        }
        .onAppear {
            if let path = folderPath {
                isFavorite = databaseManager.isFavorite(folderPath: path)
            }
        }
    }

    private func toggleFavorite() {
        guard let path = folderPath else { return }
        databaseManager.toggleFavorite(folderPath: path, folderName: title)
        isFavorite.toggle()
    }
}

struct ItemRow: View {
    let item: AudioItem

    private var iconName: String {
        item.type == .folder ? "folder.fill" : "music.note"
    }

    private var iconGradient: LinearGradient {
        if item.type == .folder {
            return LinearGradient(
                gradient: Gradient(colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [AppTheme.primaryOrange, AppTheme.secondaryOrange]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(iconGradient)
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 3)

                Image(systemName: iconName)
                    .foregroundColor(.white)
                    .font(.system(size: 24, weight: .semibold))
            }

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                Text(item.type == .folder ? "Folder" : "Audio Track")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.primaryBlue.opacity(0.6))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.8),
                                    Color.white.opacity(0.4)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.8),
                                    AppTheme.lightBlue.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: AppTheme.primaryBlue.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct AudioItemRowWithDownload: View {
    let item: AudioItem
    @ObservedObject var audioManager: AudioPlayerManager
    let databaseManager: DatabaseManager
    @ObservedObject var downloadManager: DownloadManager
    @Environment(\.managedObjectContext) private var viewContext

    @State private var trackRecord: TrackRecord?

    var body: some View {
        HStack(spacing: 16) {
            // Navigate to player
            NavigationLink(value: item) {
                HStack(spacing: 16) {
                    // Icon
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

                        Image(systemName: trackRecord?.isDownloaded == true ? "arrow.down.circle.fill" : "music.note")
                            .foregroundColor(.white)
                            .font(.system(size: 24, weight: .semibold))
                    }

                    // Text content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)

                        if let record = trackRecord {
                            if record.isDownloaded {
                                Text(String(format: "%.1f MB • Downloaded", record.trackSizeMB))
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.primaryOrange)
                            } else if let progress = downloadManager.activeDownloads[item.url ?? ""] {
                                Text(String(format: "Downloading: %.0f%%", progress.progress * 100))
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.primaryBlue)
                            } else {
                                Text("Audio Track")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("Audio Track")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Download button
            downloadButton
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
                                    Color.white.opacity(0.8),
                                    AppTheme.lightBlue.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: AppTheme.primaryBlue.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            loadTrackRecord()
            setupDownloadCompletionObserver()
        }
    }

    @ViewBuilder
    private var downloadButton: some View {
        if let urlString = item.url {
            if let progress = downloadManager.activeDownloads[urlString] {
                // Downloading
                Button(action: {
                    downloadManager.cancelDownload(url: urlString)
                }) {
                    ZStack {
                        Circle()
                            .stroke(AppTheme.primaryBlue.opacity(0.3), lineWidth: 3)
                            .frame(width: 32, height: 32)

                        Circle()
                            .trim(from: 0, to: progress.progress)
                            .stroke(AppTheme.primaryBlue, lineWidth: 3)
                            .frame(width: 32, height: 32)
                            .rotationEffect(.degrees(-90))

                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.primaryBlue)
                    }
                }
            } else if trackRecord?.isDownloaded == true {
                // Downloaded - show delete option
                Button(action: {
                    deleteDownload()
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                        .frame(width: 32, height: 32)
                }
            } else {
                // Not downloaded - show download button
                Button(action: {
                    startDownload()
                }) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.primaryBlue)
                }
            }
        }
    }

    private func loadTrackRecord() {
        guard let urlString = item.url else { return }
        trackRecord = databaseManager.getTrack(url: urlString)
    }

    private func startDownload() {
        // Create track record if doesn't exist
        if trackRecord == nil, let urlString = item.url {
            trackRecord = TrackRecord(context: viewContext, trackURL: urlString, trackName: item.name)
            databaseManager.saveOrUpdateTrack(trackRecord!)
        }

        downloadManager.startDownload(audioItem: item, databaseManager: databaseManager)
    }

    private func deleteDownload() {
        guard let urlString = item.url else { return }
        databaseManager.deleteDownloadedTrack(url: urlString)
        trackRecord = databaseManager.getTrack(url: urlString)
    }

    private func setupDownloadCompletionObserver() {
        NotificationCenter.default.addObserver(
            forName: .downloadCompleted,
            object: nil,
            queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo,
                  let url = userInfo["url"] as? String,
                  let localPath = userInfo["localPath"] as? String,
                  let fileSize = userInfo["fileSize"] as? Int64,
                  url == item.url else { return }

            databaseManager.markTrackAsDownloaded(
                url: url,
                localPath: localPath,
                fileSize: fileSize
            )
            trackRecord = databaseManager.getTrack(url: url)
        }
    }
}

struct LazyFolderBrowserView: View {
    let folderItem: AudioItem
    @ObservedObject var audioManager: AudioPlayerManager
    let databaseManager: DatabaseManager
    let downloadManager: DownloadManager
    @StateObject private var cacheManager = FolderCacheManager.shared

    @State private var items: [AudioItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isRefreshing = false

    var body: some View {
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

            Group {
                if isLoading {
                    VStack(spacing: 20) {
                        ZStack {
                            // Animated gradient circles
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            AppTheme.primaryBlue.opacity(0.3),
                                            AppTheme.lightBlue.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .blur(radius: 10)

                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(AppTheme.primaryBlue)
                        }

                        Text("Loading...")
                            .font(.headline)
                            .foregroundColor(AppTheme.primaryBlue)
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                            )
                            .shadow(color: AppTheme.primaryBlue.opacity(0.15), radius: 20, x: 0, y: 10)
                    )
                } else if let error = errorMessage {
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

                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(AppTheme.primaryOrange)
                        }

                        VStack(spacing: 12) {
                            Text("Error")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text(error)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }

                        Button(action: {
                            Task {
                              await loadFolderContents(useCache: true)
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Retry")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppTheme.primaryBlue,
                                        AppTheme.secondaryBlue
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: AppTheme.primaryBlue.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                            )
                            .shadow(color: AppTheme.primaryOrange.opacity(0.15), radius: 20, x: 0, y: 10)
                    )
                    .padding()
                } else {
                    FolderBrowserView(
                        items: items,
                        title: folderItem.name,
                        folderPath: folderItem.url,
                        audioManager: audioManager,
                        databaseManager: databaseManager,
                        downloadManager: downloadManager
                    )
                }
            }
        }
        .task {
            await loadFolderContents(useCache: true)
        }
        .refreshable {
            await loadFolderContents(useCache: false)
        }
    }

    private func loadFolderContents(useCache: Bool) async {
        guard let folderPath = folderItem.url else { return }

        // Check cache first if allowed
        if useCache, let cachedItems = cacheManager.getCachedItems(for: folderPath) {
            items = cachedItems
            isLoading = false
            return
        }

        // Cache miss or forced refresh - fetch from network
        isLoading = true
        errorMessage = nil

        do {
            let fetchedItems = try await AudioFetchService.shared.fetchFolderContents(path: folderPath)
            items = fetchedItems

            // Cache the results
            cacheManager.cacheItems(fetchedItems, for: folderPath)

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
