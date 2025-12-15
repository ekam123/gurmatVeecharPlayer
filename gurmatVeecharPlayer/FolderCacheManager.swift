import Foundation

@MainActor
class FolderCacheManager: ObservableObject {
    static let shared = FolderCacheManager()

    private var cache: [String: CachedFolder] = [:]
    private let cacheExpirationInterval: TimeInterval = 300 // 5 minutes

    private init() {}

    struct CachedFolder {
        let items: [AudioItem]
        let timestamp: Date
    }

    func getCachedItems(for path: String) -> [AudioItem]? {
        guard let cached = cache[path] else { return nil }

        // Check if cache is still valid (within 5 minutes)
        let elapsed = Date().timeIntervalSince(cached.timestamp)
        if elapsed > cacheExpirationInterval {
            // Cache expired, remove it
            cache.removeValue(forKey: path)
            return nil
        }

        return cached.items
    }

    func cacheItems(_ items: [AudioItem], for path: String) {
        cache[path] = CachedFolder(items: items, timestamp: Date())
    }

    func clearCache() {
        cache.removeAll()
    }

    func clearCacheForPath(_ path: String) {
        cache.removeValue(forKey: path)
    }
}
