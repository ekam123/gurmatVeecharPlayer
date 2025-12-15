import Foundation
import CoreData

@objc(FavoriteFolderRecord)
public class FavoriteFolderRecord: NSManagedObject, Identifiable {
    @NSManaged public var folderPath: String
    @NSManaged public var folderName: String
    @NSManaged public var dateAdded: Date

    public var id: String {
        return folderPath
    }

    convenience init(context: NSManagedObjectContext, folderPath: String, folderName: String) {
        let entity = NSEntityDescription.entity(forEntityName: "FavoriteFolderRecord", in: context)!
        self.init(entity: entity, insertInto: context)
        self.folderPath = folderPath
        self.folderName = folderName
        self.dateAdded = Date()
    }
}
