import Foundation

final class PlaybackMemory {

    private(set) var wasPlayingBeforeConversation = false

    func conversationStarted(isPlaying: Bool) {

        wasPlayingBeforeConversation = isPlaying

        print("Playback before conversation: \(isPlaying)")
    }

    func conversationEnded() {

        if wasPlayingBeforeConversation {

            print("Playback had been active before conversation.")

        }

        wasPlayingBeforeConversation = false
    }

}
