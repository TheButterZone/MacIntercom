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

import Foundation

final class AudioProcessor {

    private var gateOpen = false
    private var gateHoldFrames = 0
    private var justOpenedFrames: Int = 0
    private var gateEnvelope: Float = 0.0
    private var gateGain: Float = 0.0
    private var lastLoggedGateOpen: Bool? = nil

    private let vad = WebRTCVAD(mode: 2)
    private var vadBuffer: [Float] = []
    private let vadFrameSize = 160
    private var lastVadResult = false
    private var lastLoggedVadResult: Bool? = nil

    private var toneFilter: GoertzelFilter?
    private var toneHoldFrames = 0
    private var ctcssBuffer: [Float] = []
    private let ctcssBufferSize = 1024

    private(set) var currentGain: Float = 1.0
    private(set) var smoothedPeak: Float = 0.05

    func processAGCAndGate(_ samples: [Float]) -> [Float] {
        guard !samples.isEmpty else {
            return samples
        }

        let gated = applyNoiseGate(samples)
        return applyAutomaticGain(gated)
    }

    func setCTCSSTone(_ frequency: Float?) {
        guard let freq = frequency else {
            self.toneFilter = nil
            self.ctcssBuffer = []
            return
        }

        guard let _ = GoertzelFilter.validate(freq) else {
            fputs("Error: Unsupported CTCSS frequency '\(freq) Hz'. Please use a valid EIA CTCSS tone.\n", stderr)
            exit(1)
        }

        self.toneFilter = GoertzelFilter(targetFrequency: freq, sampleRate: 8000.0)
        self.ctcssBuffer = []
        DebugTelemetry.capture.log(
            "CTCSS Tone successfully set to standard frequency: \(freq) Hz")
    }

    private func evaluateCTCSSGate(_ samples: [Float]) -> Bool {
        guard let filter = toneFilter else { return false }

        ctcssBuffer.append(contentsOf: samples)
        if ctcssBuffer.count > ctcssBufferSize {
            ctcssBuffer.removeFirst(ctcssBuffer.count - ctcssBufferSize)
        }

        guard ctcssBuffer.count == ctcssBufferSize else {
            return gateOpen
        }

        let result = filter.evaluate(samples: ctcssBuffer)

        let openSNRThreshold: Float = 0.15
        let holdSNRThreshold: Float = 0.08
        let maxHoldFrames = 2

        let toneStrong = result.snr > openSNRThreshold
        let tonePresent = result.snr > holdSNRThreshold

        if gateOpen {
            if tonePresent {
                toneHoldFrames = maxHoldFrames
                return true
            } else if toneHoldFrames > 0 {
                toneHoldFrames -= 1
                return true
            } else {
                return false
            }
        } else {
            if toneStrong {
                toneHoldFrames = maxHoldFrames
                return true
            }
            return false
        }
    }

    private func applyNoiseGate(_ samples: [Float]) -> [Float] {
        var output = samples
        let shouldOpen: Bool

        if toneFilter != nil {
            shouldOpen = evaluateCTCSSGate(samples)
        } else if DebugFlags.useWebRTCVAD {
            vadBuffer.append(contentsOf: samples)

            var speechDetectedInAnyFrame = false
            while vadBuffer.count >= vadFrameSize {
                let chunk = Array(vadBuffer.prefix(vadFrameSize))
                vadBuffer.removeFirst(vadFrameSize)

                let pcm16Chunk = floatToPCM16(chunk)
                if vad.isSpeech(pcm16Chunk) {
                    speechDetectedInAnyFrame = true
                }
            }

            shouldOpen = speechDetectedInAnyFrame
            lastVadResult = speechDetectedInAnyFrame

            if lastVadResult != lastLoggedVadResult || gateOpen != lastLoggedGateOpen {
                DebugTelemetry.capture.log(
                    "VAD [WebRTC] State Change: speechDetected=\(lastVadResult), gateOpen=\(gateOpen)"
                )
                lastLoggedVadResult = lastVadResult
                lastLoggedGateOpen = gateOpen
            }

        } else {
            // Legacy Amplitude Envelope Squelch
            var peak: Float = 0
            for sample in output {
                peak = max(peak, abs(sample))
            }

            let envelopeAttack: Float = 0.60
            let envelopeRelease: Float = 0.03

            if peak > gateEnvelope {
                gateEnvelope += (peak - gateEnvelope) * envelopeAttack
            } else {
                gateEnvelope += (peak - gateEnvelope) * envelopeRelease
            }

            let openThreshold: Float = 0.008
            shouldOpen = gateEnvelope > openThreshold

            DebugTelemetry.capture.log(
                "VAD [Legacy Envelope]: peak=\(peak), envelope=\(gateEnvelope), shouldOpen=\(shouldOpen)"
            )
        }

        let closeThreshold: Float = 0.003
        let targetHangoverMS: Double =
            toneFilter != nil ? 50.0 : (DebugFlags.useWebRTCVAD ? 1000.0 : 40.0)

        let effectiveSampleRate: Double = 8000.0
        let bufferDurationMS = (Double(samples.count) / effectiveSampleRate) * 1000.0

        let calculatedBuffers =
            bufferDurationMS > 0
            ? Int(ceil(targetHangoverMS / bufferDurationMS)) : (DebugFlags.useWebRTCVAD ? 25 : 2)
        let holdBuffers = max(1, calculatedBuffers)

        let wasOpen = gateOpen

        if gateOpen {
            let shouldClose =
                (toneFilter != nil || DebugFlags.useWebRTCVAD)
                ? !shouldOpen : (gateEnvelope < closeThreshold)

            if shouldClose {
                if gateHoldFrames > 0 {
                    gateHoldFrames -= 1
                } else {
                    gateOpen = false
                }
            } else {
                gateHoldFrames = holdBuffers
            }
        } else {
            if shouldOpen {
                gateOpen = true
                gateHoldFrames = holdBuffers
            }
        }

        if gateOpen && !wasOpen {
            justOpenedFrames = 6
        }

        if wasOpen && !gateOpen {
            ctcssBuffer.removeAll(keepingCapacity: true)
        }

        let targetGain: Float = gateOpen ? 1.0 : 0.0

        let gateAttackRate: Float = 0.35
        let gateReleaseRate: Float = (toneFilter != nil) ? 0.4 : 0.05

        if targetGain > gateGain {
            gateGain += (targetGain - gateGain) * gateAttackRate
        } else {
            gateGain += (targetGain - gateGain) * gateReleaseRate
        }

        for i in 0..<output.count {
            output[i] *= gateGain
        }

        return output
    }

    private func applyAutomaticGain(_ samples: [Float]) -> [Float] {
        var output = samples

        var bufferPeak: Float = 0
        for sample in output {
            bufferPeak = max(bufferPeak, abs(sample))
        }

        let envelopeAttack: Float = 0.85
        let envelopeRelease: Float = 0.002

        if bufferPeak > smoothedPeak {
            smoothedPeak += (bufferPeak - smoothedPeak) * envelopeAttack
        } else {
            smoothedPeak += (bufferPeak - smoothedPeak) * envelopeRelease
        }

        let targetLevel: Float = 0.85
        let minimumSignalLevel: Float = 0.005
        let maximumGain: Float = 12.0

        var targetGain: Float

        if smoothedPeak > minimumSignalLevel {
            targetGain = targetLevel / smoothedPeak
        } else {
            targetGain = 1.0
        }

        targetGain = min(targetGain, maximumGain)

        let gainReleaseRate: Float = 0.005
        let gainAttackRate: Float = 0.60
        let onsetGainAttackRate: Float = 0.10

        if targetGain < currentGain {
            let attackRate = justOpenedFrames > 0 ? onsetGainAttackRate : gainAttackRate
            currentGain += (targetGain - currentGain) * attackRate
        } else {
            currentGain += (targetGain - currentGain) * gainReleaseRate
        }

        if justOpenedFrames > 0 {
            justOpenedFrames -= 1
        }

        for i in 0..<output.count {
            var sample = output[i] * currentGain
            sample = tanh(sample) * 0.99
            output[i] = sample
        }

        return output
    }

    private func floatToPCM16(_ samples: [Float]) -> [Int16] {
        var pcm16 = [Int16]()
        pcm16.reserveCapacity(samples.count)

        for sample in samples {
            let clamped = max(-1.0, min(1.0, sample))
            let scaled = clamped * (clamped < 0 ? 32768.0 : 32767.0)
            pcm16.append(Int16(scaled))
        }

        return pcm16
    }
}