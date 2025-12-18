import Foundation

enum AudioItemType {
    case folder
    case audio
}

struct AudioItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let type: AudioItemType
    let url: String?
    var children: [AudioItem]?

    // Playlist context for auto-play
    var playlist: [AudioItem]?
    var trackIndex: Int?

    init(id: UUID = UUID(), name: String, type: AudioItemType, url: String? = nil, children: [AudioItem]? = nil, playlist: [AudioItem]? = nil, trackIndex: Int? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.url = url
        self.children = children
        self.playlist = playlist
        self.trackIndex = trackIndex
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AudioItem, rhs: AudioItem) -> Bool {
        lhs.id == rhs.id
    }
}
