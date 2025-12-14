import SwiftUI

struct ContentView: View {
    @StateObject private var audioManager = AudioPlayerManager()

    private let rootFolders: [AudioItem] = [
        AudioItem(name: "Gurbani Santhya", type: .folder, url: "/Gurbani_Santhya"),
        AudioItem(name: "Gurbani Ucharan", type: .folder, url: "/Gurbani_Ucharan"),
        AudioItem(name: "Katha", type: .folder, url: "/Katha"),
        AudioItem(name: "Kaveeshri & Dhadi", type: .folder, url: "/Kaveeshri_and_Dhadi"),
        AudioItem(name: "Keertan", type: .folder, url: "/Keertan")
    ]

    var body: some View {
        NavigationStack {
            FolderBrowserView(items: rootFolders, title: "Audio", audioManager: audioManager)
                .navigationDestination(for: AudioItem.self) { item in
                    if item.type == .folder {
                        LazyFolderBrowserView(folderItem: item, audioManager: audioManager)
                    } else {
                        PlayerView(audioItem: item, audioManager: audioManager)
                    }
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
