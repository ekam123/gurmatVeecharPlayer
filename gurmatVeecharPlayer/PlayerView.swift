import SwiftUI

struct PlayerView: View {
    let audioItem: AudioItem
    @ObservedObject var audioManager: AudioPlayerManager

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 20) {
                    Image(systemName: "music.note")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.2))
                        )

                    Text(audioManager.currentTrackTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 15) {
                    Slider(
                        value: Binding(
                            get: { audioManager.currentTime },
                            set: { audioManager.seek(to: $0) }
                        ),
                        in: 0...max(audioManager.duration, 1)
                    )
                    .accentColor(.white)

                    HStack {
                        Text(formatTime(audioManager.currentTime))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))

                        Spacer()

                        Text(formatTime(audioManager.duration))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 30)

                HStack(spacing: 40) {
                    Button(action: {
                        audioManager.skipBackward()
                    }) {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }

                    Button(action: {
                        audioManager.togglePlayPause()
                    }) {
                        Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.white)
                    }

                    Button(action: {
                        audioManager.skipForward()
                    }) {
                        Image(systemName: "goforward.15")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
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
