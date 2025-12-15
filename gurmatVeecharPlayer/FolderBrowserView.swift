import SwiftUI

struct FolderBrowserView: View {
    let items: [AudioItem]
    let title: String
    @ObservedObject var audioManager: AudioPlayerManager
    @State private var isLoading = false

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
                        NavigationLink(value: item) {
                            ItemRow(item: item)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
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

struct LazyFolderBrowserView: View {
    let folderItem: AudioItem
    @ObservedObject var audioManager: AudioPlayerManager
    @State private var items: [AudioItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

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
                                await loadFolderContents()
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
                    FolderBrowserView(items: items, title: folderItem.name, audioManager: audioManager)
                }
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
