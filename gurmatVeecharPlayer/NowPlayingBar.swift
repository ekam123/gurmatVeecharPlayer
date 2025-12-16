import SwiftUI

struct NowPlayingBar: View {
    @ObservedObject var audioManager: AudioPlayerManager
    let onTap: () -> Void

    var body: some View {
        if audioManager.currentTrackURL != nil {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Album art / icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppTheme.primaryOrange,
                                        AppTheme.secondaryOrange
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: audioManager.isUsingLocalFile ? "arrow.down.circle.fill" : "music.note")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .semibold))
                    }

                    // Track info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(audioManager.currentTrackTitle)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            if audioManager.isUsingLocalFile {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.primaryOrange)
                            }

                            if audioManager.duration > 0 {
                                Text(formatTime(audioManager.currentTime) + " / " + formatTime(audioManager.duration))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Loading...")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()

                    // Play/Pause button
                    Button(action: {
                        audioManager.togglePlayPause()
                    }) {
                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppTheme.primaryBlue)
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
            )
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
