import Foundation
import Combine

@MainActor
class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()

    @Published var activeDownloads: [String: DownloadProgress] = [:]

    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.gurmatveechaar.downloads")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private override init() {
        super.init()
    }

    // MARK: - Download Operations

    func startDownload(audioItem: AudioItem, databaseManager: DatabaseManager) {
        guard let urlString = audioItem.url,
              let url = URL(string: urlString),
              activeDownloads[urlString] == nil else { return }

        // Create or get track record
        let track = databaseManager.getOrCreateTrack(url: urlString, trackName: audioItem.name)

        // Start download
        let task = urlSession.downloadTask(with: url)
        downloadTasks[urlString] = task
        activeDownloads[urlString] = DownloadProgress(
            url: urlString,
            trackName: audioItem.name,
            progress: 0,
            totalBytes: 0,
            downloadedBytes: 0,
            state: .downloading
        )
        task.resume()
    }

    func cancelDownload(url: String) {
        downloadTasks[url]?.cancel()
        downloadTasks.removeValue(forKey: url)
        activeDownloads.removeValue(forKey: url)
    }

    func pauseDownload(url: String) {
        downloadTasks[url]?.suspend()
        activeDownloads[url]?.state = .paused
    }

    func resumeDownload(url: String) {
        downloadTasks[url]?.resume()
        activeDownloads[url]?.state = .downloading
    }

    // MARK: - File Management

    func getLocalFileURL(for trackURL: String) -> URL? {
        let fileName = URL(string: trackURL)?.lastPathComponent ?? UUID().uuidString + ".mp3"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("Downloads").appendingPathComponent(fileName)
    }

    private func createDownloadsDirectory() throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadsPath = documentsPath.appendingPathComponent("Downloads")

        if !FileManager.default.fileExists(atPath: downloadsPath.path) {
            try FileManager.default.createDirectory(at: downloadsPath, withIntermediateDirectories: true)
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension DownloadManager: URLSessionDownloadDelegate {
    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let originalURL = downloadTask.originalRequest?.url?.absoluteString else { return }

        Task { @MainActor in
            do {
                try createDownloadsDirectory()

                guard let destinationURL = getLocalFileURL(for: originalURL) else { return }

                // Move file to permanent location
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.moveItem(at: location, to: destinationURL)

                // Get file size
                let attributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
                let fileSize = attributes[.size] as? Int64 ?? 0

                // Update progress and database
                activeDownloads[originalURL]?.state = .completed

                // Database update happens in completion handler
                if let progress = activeDownloads[originalURL] {
                    NotificationCenter.default.post(
                        name: .downloadCompleted,
                        object: nil,
                        userInfo: [
                            "url": originalURL,
                            "localPath": "Downloads/\(destinationURL.lastPathComponent)",
                            "fileSize": fileSize
                        ]
                    )
                }

                // Clean up after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.activeDownloads.removeValue(forKey: originalURL)
                    self.downloadTasks.removeValue(forKey: originalURL)
                }

            } catch {
                print("Download error: \(error)")
                activeDownloads[originalURL]?.state = .failed
            }
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let url = downloadTask.originalRequest?.url?.absoluteString else { return }

        Task { @MainActor in
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            activeDownloads[url]?.progress = progress
            activeDownloads[url]?.downloadedBytes = totalBytesWritten
            activeDownloads[url]?.totalBytes = totalBytesExpectedToWrite
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let url = task.originalRequest?.url?.absoluteString else { return }

        if let error = error {
            Task { @MainActor in
                print("Download failed: \(error)")
                activeDownloads[url]?.state = .failed
            }
        }
    }
}

// MARK: - Supporting Types

struct DownloadProgress {
    let url: String
    let trackName: String
    var progress: Double
    var totalBytes: Int64
    var downloadedBytes: Int64
    var state: DownloadState

    enum DownloadState {
        case downloading
        case paused
        case completed
        case failed
    }
}

extension Notification.Name {
    static let downloadCompleted = Notification.Name("downloadCompleted")
}
