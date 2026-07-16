import Foundation

final class MediaPlaybackState {

    static let shared = MediaPlaybackState()

    private init() {}

    private(set) var isPlaying = false {

        didSet {

            guard isPlaying != oldValue else {
                return
            }

            Logger.info("Playback is now \(isPlaying ? "PLAYING" : "PAUSED")")

            onPlaybackChanged?(isPlaying)

        }

    }

    private(set) var title: String?

    private(set) var artist: String?

    var onPlaybackChanged: ((Bool) -> Void)?

    func update(
        playing: Bool,
        title: String?,
        artist: String?
    ) {

        self.title = title

        self.artist = artist

        self.isPlaying = playing

    }

}
