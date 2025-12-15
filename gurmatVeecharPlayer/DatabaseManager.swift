import Foundation
import CoreData

@MainActor
class DatabaseManager {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Track Operations

    func getTrack(url: String) -> TrackRecord? {
        let request: NSFetchRequest<TrackRecord> = NSFetchRequest(entityName: "TrackRecord")
        request.predicate = NSPredicate(format: "trackURL == %@", url)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    func saveOrUpdateTrack(_ track: TrackRecord) {
        try? context.save()
    }

    func getOrCreateTrack(url: String, trackName: String) -> TrackRecord {
        if let existing = getTrack(url: url) {
            return existing
        }
        let newTrack = TrackRecord(context: context, trackURL: url, trackName: trackName)
        try? context.save()
        return newTrack
    }

    func updatePlaybackPosition(url: String, position: TimeInterval) {
        guard let track = getTrack(url: url) else { return }
        track.currentPlaybackTime = position
        track.lastPlayedDate = Date()
        try? context.save()
    }

    func updateTrackDuration(url: String, duration: TimeInterval) {
        guard let track = getTrack(url: url) else { return }
        track.trackDuration = duration
        try? context.save()
    }

    func markTrackAsDownloaded(url: String, localPath: String, fileSize: Int64) {
        guard let track = getTrack(url: url) else { return }
        track.isDownloaded = true
        track.localFilePath = localPath
        track.trackSizeBytes = fileSize
        track.downloadDate = Date()
        try? context.save()
    }

    func deleteDownloadedTrack(url: String) {
        guard let track = getTrack(url: url) else { return }

        // Delete the actual file
        if let localPath = track.localFilePath {
            let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(localPath)
            try? FileManager.default.removeItem(at: fileURL)
        }

        // Update database
        track.isDownloaded = false
        track.localFilePath = nil
        try? context.save()
    }

    // MARK: - Favorite Folder Operations

    func getFavorites() -> [FavoriteFolderRecord] {
        let request: NSFetchRequest<FavoriteFolderRecord> = NSFetchRequest(entityName: "FavoriteFolderRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    func isFavorite(folderPath: String) -> Bool {
        let request: NSFetchRequest<FavoriteFolderRecord> = NSFetchRequest(entityName: "FavoriteFolderRecord")
        request.predicate = NSPredicate(format: "folderPath == %@", folderPath)
        request.fetchLimit = 1
        return (try? context.fetch(request).first) != nil
    }

    func toggleFavorite(folderPath: String, folderName: String) {
        let request: NSFetchRequest<FavoriteFolderRecord> = NSFetchRequest(entityName: "FavoriteFolderRecord")
        request.predicate = NSPredicate(format: "folderPath == %@", folderPath)
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            context.delete(existing)
        } else {
            let newFavorite = FavoriteFolderRecord(context: context, folderPath: folderPath, folderName: folderName)
        }

        try? context.save()
    }
}
