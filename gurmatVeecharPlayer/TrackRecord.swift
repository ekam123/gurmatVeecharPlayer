import Foundation
import CoreData

@objc(TrackRecord)
public class TrackRecord: NSManagedObject {
    @NSManaged public var trackURL: String
    @NSManaged public var trackName: String
    @NSManaged public var trackDuration: Double
    @NSManaged public var trackSizeBytes: Int64
    @NSManaged public var currentPlaybackTime: Double
    @NSManaged public var isDownloaded: Bool
    @NSManaged public var localFilePath: String?
    @NSManaged public var lastPlayedDate: Date?
    @NSManaged public var downloadDate: Date?

    var trackSizeMB: Double {
        return Double(trackSizeBytes) / 1_048_576.0
    }

    convenience init(context: NSManagedObjectContext, trackURL: String, trackName: String) {
        let entity = NSEntityDescription.entity(forEntityName: "TrackRecord", in: context)!
        self.init(entity: entity, insertInto: context)
        self.trackURL = trackURL
        self.trackName = trackName
        self.trackDuration = 0
        self.trackSizeBytes = 0
        self.currentPlaybackTime = 0
        self.isDownloaded = false
    }
}
