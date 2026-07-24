//
// MacIntercom
// Copyright (C) 2026 TheButterZone
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see:
// https://www.gnu.org/licenses/
//

import CoreAudio
import Foundation

final class AudioCapture {

    let device: AudioDevice
    let audioBuffer: AudioBuffer

    private var ioProcID: AudioDeviceIOProcID?

    private var currentGain: Float = 1.0
    private var smoothedPeak: Float = 0.05

    var position: Float = 0
    private var downsamplePosition: Float = 0

    private var processCount = 0
    private var callbackCount = 0
    private var highestPeak: Float = 0
    private var highestProcessedPeak: Float = 0

    var onFirstCallback: (() -> Void)?
    private var hasReportedFirstCallback = false

    private let shouldDownsample: Bool
    private let outputDevice: AudioDevice
    private var upsampler: AudioResampler

    var isMuted: Bool = false

    init(
        device: AudioDevice,
        outputDevice: AudioDevice,
        audioBuffer: AudioBuffer,
        shouldDownsample: Bool
    ) {

        self.device = device
        self.outputDevice = outputDevice
        self.audioBuffer = audioBuffer
        self.shouldDownsample = shouldDownsample

        if shouldDownsample {

            self.upsampler = AudioResampler(
                inputSampleRate: 8000,
                outputSampleRate: outputDevice.sampleRate
            )

        } else {

            self.upsampler = AudioResampler(
                inputSampleRate: device.sampleRate,
                outputSampleRate: outputDevice.sampleRate
            )

        }
    }

    private func printStreamFormat() {

        var address = CoreAudioHelpers.address(
            selector: kAudioDevicePropertyStreamFormat,
            scope: kAudioDevicePropertyScopeInput
        )

        var format = AudioStreamBasicDescription()
        var size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)

        let status = AudioObjectGetPropertyData(
            device.id,
            &address,
            0,
            nil,
            &size,
            &format
        )

        if status == noErr {
            DebugTelemetry.capture.log(
                """
                STREAM FORMAT
                device=\(device.name)
                sampleRate=\(format.mSampleRate)
                formatID=\(format.mFormatID)
                flags=\(format.mFormatFlags)
                bits=\(format.mBitsPerChannel)
                channels=\(format.mChannelsPerFrame)
                bytesPerFrame=\(format.mBytesPerFrame)
                """
            )
        } else {
            DebugTelemetry.capture.log(
                """
                STREAM FORMAT ERROR
                device=\(device.name)
                status=\(status)
                """
            )
        }
    }

    func start() {

        printStreamFormat()

        var address = CoreAudioHelpers.address(
            selector: kAudioDevicePropertyBufferFrameSize,
            scope: kAudioObjectPropertyScopeInput
        )

        var frames: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)

        if AudioObjectGetPropertyData(
            device.id,
            &address,
            0,
            nil,
            &size,
            &frames
        ) == noErr {

            DebugTelemetry.capture.log(
                """
                CAPTURE START
                device=\(device.name)
                id=\(device.id)
                frames=\(frames)
                """
            )

        }

        let status = AudioDeviceCreateIOProcID(
            device.id,
            {
                (
                    inDevice,
                    inNow,
                    inInputData,
                    inInputTime,
                    outOutputData,
                    inOutputTime,
                    clientData
                ) -> OSStatus in

                if let clientData = clientData {

                    let capture = Unmanaged<AudioCapture>
                        .fromOpaque(clientData)
                        .takeUnretainedValue()

                    capture.captureInput(inInputData)
                }

                return noErr

            },
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &ioProcID
        )

        if status != noErr {
            Logger.error(
                "Failed to create capture IOProc \(device.name): \(status)"
            )
            return
        }

        let shouldStart: Bool

        if device.transport == "Bluetooth" {

            shouldStart =
                DebugFlags.enableBluetoothCapture

        } else {

            shouldStart =
                DebugFlags.enableComputerCapture

        }

        if shouldStart {

            let startStatus = AudioDeviceStart(
                device.id,
                ioProcID!
            )

            if startStatus != noErr {

                Logger.error(
                    "Failed to start capture device \(device.name): \(startStatus)"
                )

            }

        } else {

            Logger.info(
                "DEBUG: Capture disabled for \(device.name)"
            )

        }

    }

    private func captureInput(
        _ inInputData: UnsafePointer<AudioBufferList>?
    ) {

        guard let inInputData = inInputData else {
            return
        }

        self.callbackCount += 1

        let bufferList = UnsafeMutableAudioBufferListPointer(
            UnsafeMutablePointer(mutating: inInputData)
        )

        if self.callbackCount == 1 {

            DebugTelemetry.capture.log(
                "Audio buffers: \(bufferList.count)"
            )

            for (index, buffer) in bufferList.enumerated() {

                DebugTelemetry.capture.log(
                    """
                    Buffer
                    index=\(index)
                    bytes=\(buffer.mDataByteSize)
                    channels=\(buffer.mNumberChannels)
                    """
                )
            }
        }

        if let data = bufferList[0].mData {

            if self.isMuted {
                memset(data, 0, Int(bufferList[0].mDataByteSize))
            }

            let samples = data.assumingMemoryBound(
                to: Float.self
            )

            if !self.hasReportedFirstCallback {

                self.hasReportedFirstCallback = true

                DispatchQueue.main.async {

                    self.onFirstCallback?()

                }
            }

            let sampleCount =
                Int(
                    bufferList[0].mDataByteSize
                ) / MemoryLayout<Float>.size

            if self.callbackCount == 1 {

                DebugTelemetry.capture.log(
                    """
                    FIRST CALLBACK
                    device=\(device.name)
                    samples=\(sampleCount)
                    """
                )
            }

            var peak: Float = 0

            for i in 0..<sampleCount {

                let normalized = abs(samples[i])

                if normalized > peak {
                    peak = normalized
                }

                if peak > self.highestPeak {
                    self.highestPeak = peak
                }
            }

            if self.callbackCount % 500 == 0 {
                Logger.levels(
                    "Highest input peak: \(self.highestPeak)"
                )
                self.highestPeak = 0
            }

            if self.callbackCount % 100 == 0 {

                DebugTelemetry.capture.log(
                    """
                    RAW CAPTURE
                    device=\(device.name)
                    rate=\(device.sampleRate)
                    samples=\(sampleCount)
                    channels=\(bufferList[0].mNumberChannels)
                    """
                )

            }

            let capturedSamples = Array(
                UnsafeBufferPointer(
                    start: samples,
                    count: sampleCount
                )
            )

            if self.callbackCount % 100 == 0 {

                DebugTelemetry.capture.log(
                    """
                    CAPTURE
                    device=\(device.name)
                    samples=\(sampleCount)
                    downsample=\(self.shouldDownsample)
                    highestInputPeak=\(self.highestPeak)
                    queue=\(self.audioBuffer.sampleCount())
                    """
                )
            }

            if self.shouldDownsample {

                let channels = Int(bufferList[0].mNumberChannels)

                let mono8k = self.downsampleTo8kMono(
                    capturedSamples,
                    channels: channels
                )

                let processed: [Float]

                if DebugFlags.enableAGC {

                    processed = applyAutomaticGain(mono8k)

                } else {

                    processed = mono8k

                }

                if DebugFlags.enableAGC && self.callbackCount % 100 == 0 {

                    DebugTelemetry.capture.log(
                        """
                        AGC
                        device=\(device.name)
                        gain=\(self.currentGain)
                        peak=\(self.smoothedPeak)
                        """
                    )

                }

                if self.callbackCount % 100 == 0 {

                    DebugTelemetry.capture.log(
                        "DOWNSAMPLED=\(mono8k.count)"
                    )

                }

                for sample in processed {

                    let peak = abs(sample)

                    if peak > self.highestProcessedPeak {
                        self.highestProcessedPeak = peak
                    }
                }

                if DebugFlags.enableAGC && self.callbackCount % 500 == 0 {

                    Logger.levels(
                        "Highest processed peak: \(self.highestProcessedPeak)"
                    )
                    self.highestProcessedPeak = 0
                }

                if DebugFlags.enableAGC && self.callbackCount % 500 == 0 {

                    Logger.levels(
                        "Gain: \(self.currentGain) Peak: \(self.smoothedPeak)"
                    )

                }

                DebugTelemetry.capture.log(
                    """
                    CTOB
                    mono8k=\(mono8k.count)
                    processed=\(processed.count)
                    queue=\(self.audioBuffer.sampleCount())
                    """
                )

                self.audioBuffer.write(
                    processed
                )

            } else {

                let channels = Int(bufferList[0].mNumberChannels)
                let monoInputSamples: [Float]

                if channels == 2 {
                    var extractedMono = [Float]()
                    extractedMono.reserveCapacity(capturedSamples.count / 2)

                    for i in stride(from: 0, to: capturedSamples.count - 1, by: 2) {
                        let left = capturedSamples[i]
                        let right = capturedSamples[i + 1]

                        let leftLevel = abs(left)
                        let rightLevel = abs(right)

                        if leftLevel > rightLevel * 2 {
                            extractedMono.append(left)
                        } else if rightLevel > leftLevel * 2 {
                            extractedMono.append(right)
                        } else {
                            extractedMono.append((left + right) * 0.5)
                        }
                    }
                    monoInputSamples = extractedMono
                } else {
                    monoInputSamples = capturedSamples
                }

                let mono44100 = self.resampleToOutputStereo(
                    monoInputSamples
                )

                var peak: Float = 0

                for sample in mono44100 {
                    peak = max(peak, abs(sample))
                }

                if callbackCount % 100 == 0 {

                    DebugTelemetry.output.log(
                        """
                        BTOC
                        peak=\(peak)
                        samples=\(mono44100.count)
                        queue=\(self.audioBuffer.sampleCount())
                        """
                    )
                }

                let processed: [Float]

                if DebugFlags.enableAGC {

                    processed = applyAutomaticGain(mono44100)

                } else {

                    processed = mono44100

                }

                if DebugFlags.enableAGC && self.callbackCount % 100 == 0 {

                    DebugTelemetry.capture.log(
                        """
                        AGC
                        device=\(device.name)
                        gain=\(self.currentGain)
                        peak=\(self.smoothedPeak)
                        """
                    )

                }

                for sample in processed {
                    let peak = abs(sample)

                    if peak > self.highestProcessedPeak {
                        self.highestProcessedPeak = peak
                    }
                }

                if DebugFlags.enableAGC && self.callbackCount % 500 == 0 {

                    Logger.levels(
                        "Highest processed peak: \(self.highestProcessedPeak)"
                    )
                    self.highestProcessedPeak = 0
                }

                if DebugFlags.enableAGC && self.callbackCount % 500 == 0 {

                    Logger.levels(
                        "Gain: \(self.currentGain) Peak: \(self.smoothedPeak)"
                    )
                }

                self.audioBuffer.write(
                    processed
                )

            }

            if self.callbackCount % 100 == 0 {
                Logger.queue(
                    "BT queue: \(self.audioBuffer.sampleCount())"
                )
            }

        }
    }

    private func applyAutomaticGain(
        _ samples: [Float]
    ) -> [Float] {

        var output = samples

        var bufferPeak: Float = 0
        for sample in output {
            bufferPeak = max(bufferPeak, abs(sample))
        }

        // Update the envelope once per buffer.
        smoothedPeak =
            smoothedPeak * 0.95 + bufferPeak * 0.05

        // Lowered from 0.95 to a comfortable listening volume
        let targetLevel: Float = 0.65

        // A middle ground: low enough to catch the Mixer, high enough to ignore USB silence
        let minimumSignalLevel: Float = 0.005

        var targetGain: Float

        if smoothedPeak > minimumSignalLevel {
            targetGain = targetLevel / smoothedPeak
        } else {
            // If it falls below the minimum signal (true silence), fade back to no boost
            targetGain = 1.0
        }

        // Capped at 30x boost. 100x is too aggressive for standard digital mics.
        targetGain = min(targetGain, 30.0)

        if targetGain < currentGain {
            // FAST ATTACK: Signal suddenly got loud. Drop gain rapidly (20% per buffer) to prevent clipping/fuzziness.
            currentGain += (targetGain - currentGain) * 0.20
        } else {
            // SLOW RELEASE: Signal is quiet. Raise gain slowly (1% per buffer) so room noise doesn't pump.
            currentGain += (targetGain - currentGain) * 0.01
        }

        // Slightly safer hard ceiling
        let maxOutput: Float = 0.95

        for i in 0..<output.count {
            var sample = output[i] * currentGain
            // Hard clipper
            sample = max(-maxOutput, min(maxOutput, sample))
            output[i] = sample
        }

        return output
    }

    private func downsampleTo8kMono(
        _ samples: [Float],
        channels: Int
    ) -> [Float] {

        let inputRate = Float(device.sampleRate)
        let outputRate: Float = 8000

        let step = inputRate / outputRate

        var output: [Float] = []

        var position = downsamplePosition

        let frameCount = samples.count / channels

        while Int(position) + 1 < frameCount {

            let frame = Int(position)
            let fraction = position - Float(frame)
            let mono: Float

            if channels == 2 {
                let left0 = samples[frame * 2]
                let left1 = samples[(frame + 1) * 2]

                let right0 = samples[frame * 2 + 1]
                let right1 = samples[(frame + 1) * 2 + 1]

                let left = left0 + (left1 - left0) * fraction
                let right = right0 + (right1 - right0) * fraction

                let leftLevel = abs(left)
                let rightLevel = abs(right)

                if leftLevel > rightLevel * 2 {
                    mono = left
                } else if rightLevel > leftLevel * 2 {
                    mono = right
                } else {
                    mono = (left + right) * 0.5
                }
            } else {
                let val0 = samples[frame]
                let val1 = samples[frame + 1]
                mono = val0 + (val1 - val0) * fraction
            }

            output.append(
                max(-1.0, min(1.0, mono))
            )

            position += step
        }

        position -= Float(frameCount)
        downsamplePosition = max(0, position)

        return output
    }

    private func resampleToOutputStereo(
        _ samples: [Float]
    ) -> [Float] {

        let output = upsampler.process(samples)

        DebugTelemetry.capture.log(
            """
            BT RESAMPLE OUTPUT
            inputSamples=\(samples.count)
            outputSamples=\(output.count)
            """
        )

        return output
    }
}
