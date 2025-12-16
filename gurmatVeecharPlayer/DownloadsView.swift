import SwiftUI
import CoreData

struct DownloadsView: View {
    @ObservedObject var audioManager: AudioPlayerManager
    let databaseManager: DatabaseManager
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var navigationState: NavigationState
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TrackRecord.downloadDate, ascending: false)],
        predicate: NSPredicate(format: "isDownloaded == YES"),
        animation: .default)
    private var downloadedTracks: FetchedResults<TrackRecord>

    @State private var groupByFolder = true

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

                if downloadedTracks.isEmpty {
                    // Empty state
                    VStack(spacing: 24) {
                        ZStack {
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
                                .frame(width: 120, height: 120)
                                .blur(radius: 15)

                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 50))
                                .foregroundColor(AppTheme.primaryBlue)
                        }

                        VStack(spacing: 12) {
                            Text("No Downloads")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text("Download tracks for offline playback")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                    }
                    .padding(40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                            if groupByFolder {
                                ForEach(groupedByFolder.keys.sorted(), id: \.self) { folderName in
                                    Section(header: FolderHeaderView(folderName: folderName)) {
                                        ForEach(groupedByFolder[folderName] ?? [], id: \.trackURL) { track in
                                            DownloadedTrackRow(
                                                track: track,
                                                audioManager: audioManager,
                                                databaseManager: databaseManager
                                            )
                                        }
                                    }
                                }
                            } else {
                                ForEach(Array(downloadedTracks), id: \.trackURL) { track in
                                    DownloadedTrackRow(
                                        track: track,
                                        audioManager: audioManager,
                                        databaseManager: databaseManager
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Downloads")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !downloadedTracks.isEmpty {
                        Button(action: {
                            groupByFolder.toggle()
                        }) {
                            Image(systemName: groupByFolder ? "list.bullet" : "folder.fill")
                                .foregroundColor(AppTheme.primaryBlue)
                        }
                    }
                }
            }
            .navigationDestination(for: AudioItem.self) { item in
                PlayerView(
                    audioItem: item,
                    audioManager: audioManager,
                    databaseManager: databaseManager
                )
                .environmentObject(navigationState)
            }
        }
    }

    private var groupedByFolder: [String: [TrackRecord]] {
        Dictionary(grouping: Array(downloadedTracks)) { track in
            extractFolderName(from: track.trackURL)
        }
    }

    private func extractFolderName(from url: String) -> String {
        let components = url.split(separator: "/")
        if components.count > 1 {
            // Get the parent folder name
            let folderComponent = components[components.count - 2]
            return String(folderComponent)
                .replacingOccurrences(of: "_", with: " ")
                .replacingOccurrences(of: "%20", with: " ")
        }
        return "Other"
    }
}

struct FolderHeaderView: View {
    let folderName: String

    var body: some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundColor(AppTheme.primaryBlue)
                .font(.system(size: 16, weight: .semibold))

            Text(folderName)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.7))
        )
    }
}

struct DownloadedTrackRow: View {
    let track: TrackRecord
    @ObservedObject var audioManager: AudioPlayerManager
    let databaseManager: DatabaseManager

    var body: some View {
        NavigationLink(value: AudioItem(
            name: track.trackName,
            type: .audio,
            url: track.trackURL
        )) {
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

                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 24, weight: .semibold))
                }

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.trackName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text(String(format: "%.1f MB", track.trackSizeMB))
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.primaryOrange)

                        if track.trackDuration > 0 {
                            Text("•")
                                .foregroundColor(.secondary)

                            Text(formatDuration(track.trackDuration))
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // Delete button
                Button(action: {
                    databaseManager.deleteDownloadedTrack(url: track.trackURL)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(PlainButtonStyle())
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
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
