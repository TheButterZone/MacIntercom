import Foundation
import Dispatch

final class MediaRemoteObserver {

    static let shared = MediaRemoteObserver()

    private var frameworkHandle: UnsafeMutableRawPointer?

    private typealias IsPlayingBlock =
        @convention(block) (Bool) -> Void

    private typealias GetIsPlaying =
        @convention(c)
        (
            DispatchQueue,
            @escaping IsPlayingBlock
        ) -> Void

    private var getIsPlaying: GetIsPlaying?

    private init() {}

    func start() {

        frameworkHandle = dlopen(
            "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote",
            RTLD_NOW
        )

        guard frameworkHandle != nil else {

            Logger.error("Couldn't load MediaRemote.framework")

            return
        }

        Logger.info("MediaRemote loaded")

        guard let symbol = dlsym(
            frameworkHandle,
            "MRMediaRemoteGetNowPlayingApplicationIsPlaying"
        ) else {

            Logger.error("Couldn't locate MRMediaRemoteGetNowPlayingApplicationIsPlaying")

            return
        }

        getIsPlaying =
            unsafeBitCast(
                symbol,
                to: GetIsPlaying.self
            )

        Logger.info("MediaRemote playback API ready")

     //   Timer.scheduledTimer(
     //       withTimeInterval: 1.0,
     //       repeats: true
     //   ) { _ in

     //       self.poll()

     //   }
    }//

    private func poll() {

	guard let getIsPlaying = getIsPlaying else {
	    return
	}

        getIsPlaying(.main) { playing in

            MediaPlaybackState.shared.update(
                playing: playing,
                title: nil,
                artist: nil
            )

        }

    }

}
