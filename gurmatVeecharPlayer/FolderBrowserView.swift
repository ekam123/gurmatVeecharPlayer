import SwiftUI

struct FolderBrowserView: View {
    let items: [AudioItem]
    let title: String
    @ObservedObject var audioManager: AudioPlayerManager
    @State private var isLoading = false

    var body: some View {
        List {
            ForEach(items) { item in
                NavigationLink(value: item) {
                    ItemRow(item: item)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct ItemRow: View {
    let item: AudioItem

    private var iconName: String {
        item.type == .folder ? "folder.fill" : "music.note"
    }

    private var iconColor: Color {
        item.type == .folder ? .blue : .purple
    }

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.title2)
                .frame(width: 30)

            Text(item.name)
                .font(.body)
        }
        .padding(.vertical, 8)
    }
}

struct LazyFolderBrowserView: View {
    let folderItem: AudioItem
    @ObservedObject var audioManager: AudioPlayerManager
    @State private var items: [AudioItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
            } else if let error = errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Error")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task {
                            await loadFolderContents()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else {
                FolderBrowserView(items: items, title: folderItem.name, audioManager: audioManager)
            }
        }
        .task {
            await loadFolderContents()
        }
    }

    private func loadFolderContents() async {
        isLoading = true
        errorMessage = nil

        do {
            if let folderPath = folderItem.url {
                items = try await AudioFetchService.shared.fetchFolderContents(path: folderPath)
            }
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
