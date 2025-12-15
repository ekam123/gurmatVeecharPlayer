import CoreData

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // Create the model programmatically
        let model = NSManagedObjectModel()

        // TrackRecord Entity
        let trackEntity = NSEntityDescription()
        trackEntity.name = "TrackRecord"
        trackEntity.managedObjectClassName = "TrackRecord"

        let trackURLAttr = NSAttributeDescription()
        trackURLAttr.name = "trackURL"
        trackURLAttr.type = .string
        trackURLAttr.isOptional = false

        let trackNameAttr = NSAttributeDescription()
        trackNameAttr.name = "trackName"
        trackNameAttr.type = .string
        trackNameAttr.isOptional = false

        let trackDurationAttr = NSAttributeDescription()
        trackDurationAttr.name = "trackDuration"
        trackDurationAttr.type = .double
        trackDurationAttr.defaultValue = 0.0

        let trackSizeBytesAttr = NSAttributeDescription()
        trackSizeBytesAttr.name = "trackSizeBytes"
        trackSizeBytesAttr.type = .integer64
        trackSizeBytesAttr.defaultValue = 0

        let currentPlaybackTimeAttr = NSAttributeDescription()
        currentPlaybackTimeAttr.name = "currentPlaybackTime"
        currentPlaybackTimeAttr.type = .double
        currentPlaybackTimeAttr.defaultValue = 0.0

        let isDownloadedAttr = NSAttributeDescription()
        isDownloadedAttr.name = "isDownloaded"
        isDownloadedAttr.type = .boolean
        isDownloadedAttr.defaultValue = false

        let localFilePathAttr = NSAttributeDescription()
        localFilePathAttr.name = "localFilePath"
        localFilePathAttr.type = .string
        localFilePathAttr.isOptional = true

        let lastPlayedDateAttr = NSAttributeDescription()
        lastPlayedDateAttr.name = "lastPlayedDate"
        lastPlayedDateAttr.type = .date
        lastPlayedDateAttr.isOptional = true

        let downloadDateAttr = NSAttributeDescription()
        downloadDateAttr.name = "downloadDate"
        downloadDateAttr.type = .date
        downloadDateAttr.isOptional = true

        trackEntity.properties = [
            trackURLAttr, trackNameAttr, trackDurationAttr, trackSizeBytesAttr,
            currentPlaybackTimeAttr, isDownloadedAttr, localFilePathAttr,
            lastPlayedDateAttr, downloadDateAttr
        ]

        // FavoriteFolderRecord Entity
        let favoriteEntity = NSEntityDescription()
        favoriteEntity.name = "FavoriteFolderRecord"
        favoriteEntity.managedObjectClassName = "FavoriteFolderRecord"

        let folderPathAttr = NSAttributeDescription()
        folderPathAttr.name = "folderPath"
        folderPathAttr.type = .string
        folderPathAttr.isOptional = false

        let folderNameAttr = NSAttributeDescription()
        folderNameAttr.name = "folderName"
        folderNameAttr.type = .string
        folderNameAttr.isOptional = false

        let dateAddedAttr = NSAttributeDescription()
        dateAddedAttr.name = "dateAdded"
        dateAddedAttr.type = .date
        dateAddedAttr.isOptional = false

        favoriteEntity.properties = [folderPathAttr, folderNameAttr, dateAddedAttr]

        model.entities = [trackEntity, favoriteEntity]

        // Create container with the programmatic model
        container = NSPersistentContainer(name: "GurmatVeecharModel", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
