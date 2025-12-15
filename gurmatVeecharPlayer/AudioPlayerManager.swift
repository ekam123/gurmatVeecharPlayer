import Foundation
import AVFoundation
import Combine
import UIKit

class AudioPlayerManager: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentTrackTitle: String = "No Track Selected"
    @Published var currentTrackURL: String?
    @Published var isUsingLocalFile: Bool = false

    private var audioPlayer: AVPlayer?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var itemObserver: NSKeyValueObservation?
    private var databaseManager: DatabaseManager?
    private var lastSavedPosition: TimeInterval = 0

    override init() {
        super.init()
        setupAudioSession()
        setupNotifications()
    }

    @MainActor func setDatabaseManager(_ manager: DatabaseManager) {
        self.databaseManager = manager
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

  @MainActor func loadAudio(url: URL, trackName: String) {
        removeObservers()

        currentTrackURL = url.absoluteString
        currentTrackTitle = trackName

        // Check for local file first
        let localURL = checkForLocalFile(remoteURL: url.absoluteString)
        let playbackURL = localURL ?? url
        isUsingLocalFile = localURL != nil

        let playerItem = AVPlayerItem(url: playbackURL)
        audioPlayer = AVPlayer(playerItem: playerItem)

        // Try to restore playback position
        if let trackRecord = databaseManager?.getTrack(url: url.absoluteString),
           trackRecord.currentPlaybackTime > 0 {
            currentTime = trackRecord.currentPlaybackTime
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.seek(to: trackRecord.currentPlaybackTime)
            }
        } else {
            currentTime = 0
        }

        setupTimeObserver()
        setupStatusObserver()
        setupItemObserver(for: playerItem)
    }

  @MainActor private func checkForLocalFile(remoteURL: String) -> URL? {
        guard let track = databaseManager?.getTrack(url: remoteURL),
              track.isDownloaded,
              let localPath = track.localFilePath else {
            return nil
        }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let localURL = documentsPath.appendingPathComponent(localPath)

        // Verify file exists
        guard FileManager.default.fileExists(atPath: localURL.path) else {
            // File missing, update database
            databaseManager?.deleteDownloadedTrack(url: remoteURL)
            return nil
        }

        return localURL
    }

    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = audioPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            Task { @MainActor in
                self.currentTime = time.seconds

                // Auto-save position every 5 seconds
                if abs(self.currentTime - self.lastSavedPosition) >= 5.0 {
                    self.saveCurrentPosition()
                }
            }
        }
    }

    private func setupStatusObserver() {
        statusObserver = audioPlayer?.currentItem?.observe(\.status, options: [.new, .old]) { [weak self] item, _ in
            guard let self = self else { return }
            if item.status == .readyToPlay {
                let newDuration = item.duration.seconds
                Task { @MainActor in
                    self.duration = newDuration

                    // Update database with duration
                    if let url = self.currentTrackURL {
                        self.databaseManager?.updateTrackDuration(url: url, duration: newDuration)
                    }
                }
            }
        }
    }

    private func setupItemObserver(for item: AVPlayerItem) {
        itemObserver = item.observe(\.duration, options: [.new]) { [weak self] item, _ in
            guard let self = self else { return }
            let duration = item.duration.seconds
            if duration.isFinite {
                Task { @MainActor in
                    self.duration = duration

                    // Update database
                    if let url = self.currentTrackURL {
                        self.databaseManager?.updateTrackDuration(url: url, duration: duration)
                    }
                }
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )
    }

    @MainActor func play() {
        audioPlayer?.play()
        isPlaying = true
    }

    @MainActor func pause() {
        audioPlayer?.pause()
        isPlaying = false
        saveCurrentPosition()
    }

    @MainActor func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    @MainActor func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        audioPlayer?.seek(to: cmTime)
        currentTime = time
    }

    @MainActor func skipForward(_ seconds: TimeInterval = 15) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }

    @MainActor func skipBackward(_ seconds: TimeInterval = 15) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }

    @objc private func playerDidFinishPlaying() {
        Task { @MainActor in
            isPlaying = false
            currentTime = 0
            saveCurrentPosition()
        }
    }

  @MainActor private func saveCurrentPosition() {
        guard let url = currentTrackURL else { return }
        databaseManager?.updatePlaybackPosition(url: url, position: currentTime)
        lastSavedPosition = currentTime
    }

    @objc private func appWillResignActive() {
        Task { @MainActor in
            saveCurrentPosition()
        }
    }

    @objc private func appDidEnterBackground() {
        Task { @MainActor in
            saveCurrentPosition()
        }
    }

    private func removeObservers() {
        if let observer = timeObserver {
            audioPlayer?.removeTimeObserver(observer)
            timeObserver = nil
        }

        statusObserver?.invalidate()
        statusObserver = nil

        itemObserver?.invalidate()
        itemObserver = nil

        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }

    deinit {
        removeObservers()
        NotificationCenter.default.removeObserver(self)
    }
}
