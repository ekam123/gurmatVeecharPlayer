import Foundation
import AVFoundation
import Combine

class AudioPlayerManager: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentTrackTitle: String = "No Track Selected"

    private var audioPlayer: AVPlayer?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var itemObserver: NSKeyValueObservation?

    override init() {
        super.init()
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    func loadAudio(url: URL) {
        removeObservers()

        let playerItem = AVPlayerItem(url: url)
        audioPlayer = AVPlayer(playerItem: playerItem)

        currentTime = 0
        currentTrackTitle = url.lastPathComponent

        setupTimeObserver()
        setupStatusObserver()
        setupItemObserver(for: playerItem)
    }

    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = audioPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
        }
    }

    private func setupStatusObserver() {
        statusObserver = audioPlayer?.currentItem?.observe(\.status, options: [.new, .old]) { [weak self] item, _ in
            guard let self = self else { return }
            if item.status == .readyToPlay {
                self.duration = item.duration.seconds
            }
        }
    }

    private func setupItemObserver(for item: AVPlayerItem) {
        itemObserver = item.observe(\.duration, options: [.new]) { [weak self] item, _ in
            guard let self = self else { return }
            let duration = item.duration.seconds
            if duration.isFinite {
                self.duration = duration
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )
    }

    func play() {
        audioPlayer?.play()
        isPlaying = true
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        audioPlayer?.seek(to: cmTime)
        currentTime = time
    }

    func skipForward(_ seconds: TimeInterval = 15) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }

    func skipBackward(_ seconds: TimeInterval = 15) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }

    @objc private func playerDidFinishPlaying() {
        isPlaying = false
        currentTime = 0
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

        NotificationCenter.default.removeObserver(self)
    }

    deinit {
        removeObservers()
    }
}
