import SwiftUI

struct PlayerView: View {
    let audioItem: AudioItem
    @ObservedObject var audioManager: AudioPlayerManager

    var body: some View {
        ZStack {
            // Enhanced gradient background with blue-orange theme
            LinearGradient(
                gradient: Gradient(colors: [
                    AppTheme.primaryBlue,
                    AppTheme.secondaryBlue,
                    AppTheme.primaryOrange.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Album art with glassmorphism
                VStack(spacing: 20) {
                    ZStack {
                        // Outer glow
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppTheme.lightOrange.opacity(0.4),
                                        AppTheme.lightBlue.opacity(0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 200, height: 200)
                            .blur(radius: 20)

                        // Glass background
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 180, height: 180)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)

                        // Icon
                        Image(systemName: "music.note")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white)
                    }

                    Text(audioManager.currentTrackTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                }

                // Time slider with glass effect
                VStack(spacing: 15) {
                    Slider(
                        value: Binding(
                            get: { audioManager.currentTime },
                            set: { audioManager.seek(to: $0) }
                        ),
                        in: 0...max(audioManager.duration, 1)
                    )
                    .accentColor(AppTheme.lightOrange)
                    .tint(AppTheme.lightOrange)

                    HStack {
                        Text(formatTime(audioManager.currentTime))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))

                        Spacer()

                        Text(formatTime(audioManager.duration))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)

                // Control buttons with glass effect
                HStack(spacing: 50) {
                    Button(action: {
                        audioManager.skipBackward()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )

                            Image(systemName: "gobackward.15")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }

                    Button(action: {
                        audioManager.togglePlayPause()
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            AppTheme.lightOrange,
                                            AppTheme.secondaryOrange
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: AppTheme.primaryOrange.opacity(0.5), radius: 15, x: 0, y: 8)

                            Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }

                    Button(action: {
                        audioManager.skipForward()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )

                            Image(systemName: "goforward.15")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle(audioItem.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let urlString = audioItem.url, let url = URL(string: urlString) {
                audioManager.loadAudio(url: url)
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
