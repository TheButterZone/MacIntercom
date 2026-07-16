import Foundation

final class ConversationController {

    enum Trigger {
        case bluetoothButton
        case vox
        case app
    }

    private(set) var state: ConversationState = .idle {

        didSet {

            guard state != oldValue else {
                return
            }

            Logger.info(
                "Conversation state: \(oldValue) → \(state)"
            )

            onStateChanged?(state)

        }

    }

    var onStateChanged: ((ConversationState) -> Void)?

    private var playbackWasActive = false

    init() {

        MediaPlaybackState.shared.onPlaybackChanged = { [weak self] playing in

            self?.playbackChanged(playing)

        }

    }

    private func playbackChanged(_ playing: Bool) {

        Logger.info(
            "Playback changed: \(playing ? "ACTIVE" : "INACTIVE")"
        )

    }

    func begin(trigger: Trigger) {

        guard state == .idle else {
            return
        }

        playbackWasActive =
            MediaPlaybackState.shared.isPlaying

        Logger.info(
            "Playback before conversation: \(playbackWasActive)"
        )

        state = .starting

        state = .active

    }

    func end(trigger: Trigger) {

        guard state == .active else {
            return
        }

        state = .ending

        if playbackWasActive {

            Logger.info(
                "Playback had been active before conversation."
            )

        }

        playbackWasActive = false

        state = .idle

    }

    func toggle(trigger: Trigger) {

        switch state {

        case .idle:

            begin(trigger: trigger)

        case .active:

            end(trigger: trigger)

        default:

            break

        }

    }

}
