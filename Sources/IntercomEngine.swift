import Foundation

final class IntercomEngine {

    private let buffer: AudioBuffer

    let capture: AudioCapture
    private let output: AudioOutput

    private let primeBuffer: Bool

    private var started = false

    init(
        name: String,
        route: IntercomRoute,
        shouldDownsample: Bool,
        primeBuffer: Bool
    ) {

        self.primeBuffer = primeBuffer

        buffer = AudioBuffer(name: name)

        DebugTelemetry.capture.log(
            """
            ENGINE=\(name)
            INPUT=\(route.input.name)
            INPUT_RATE=\(route.input.sampleRate)
            OUTPUT=\(route.output.name)
            OUTPUT_RATE=\(route.output.sampleRate)
            DOWNSAMPLE=\(shouldDownsample)
            PRIME=\(primeBuffer)
            """
        )

        capture = AudioCapture(
            device: route.input,
            outputDevice: route.output,
            audioBuffer: buffer,
            shouldDownsample: shouldDownsample
        )

        output = AudioOutput(
            device: route.output,
            audioBuffer: buffer
        )
    }


    func start() {

        if started {

DebugTelemetry.capture.log(
    """
    ENGINE ALREADY STARTED
    output=\(output.device.name)
    """
)

            return
        }

        started = true

Logger.info(
    "Intercom  🎤 \(capture.device.name) → 🔊 \(output.device.name)  🎵 tone=\(DebugFlags.generateTestTone)"
)


        if DebugFlags.generateTestTone {

Logger.info(
    "🎵 Tone test  🔊 \(output.device.name)"
)

            output.start()
            return
        }


        capture.start()


        if primeBuffer {

            DispatchQueue.global(qos: .userInitiated).async {

                let targetSamples = 512

                while self.buffer.sampleCount() < targetSamples {
                    usleep(10_000)
                }

DebugTelemetry.capture.log(
    """
    AUDIO FLOW START
    output=\(self.output.device.name)
    queued=\(self.buffer.sampleCount())
    """
)

Logger.info(
    "🔄  Audio flowing  🎤 \(self.capture.device.name) → 🔊 \(self.output.device.name)"
)

                self.output.start()
            }

        } else {

            output.start()

        }
    }
}