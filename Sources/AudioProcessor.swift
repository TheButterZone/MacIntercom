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

    private let vad = WebRTCVAD(mode: 3)
    private var vadBuffer: [Float] = []
    private let vadFrameSize = 160
    private var lastVadResult = false
    private var lastLoggedVadResult: Bool? = nil

    private(set) var currentGain: Float = 1.0
    private(set) var smoothedPeak: Float = 0.05

    func processAGCAndGate(_ samples: [Float]) -> [Float] {
        guard !samples.isEmpty else {
            return samples
        }
        
        let gated = applyNoiseGate(samples)
        return applyAutomaticGain(gated)
    }

    private func applyNoiseGate(_ samples: [Float]) -> [Float] {
        var output = samples
        let shouldOpen: Bool

        if DebugFlags.useWebRTCVAD {
            vadBuffer.append(contentsOf: samples)
            
            while vadBuffer.count >= vadFrameSize {
                let chunk = Array(vadBuffer.prefix(vadFrameSize))
                vadBuffer.removeFirst(vadFrameSize)
                
                let pcm16Chunk = floatToPCM16(chunk)
                lastVadResult = vad.isSpeech(pcm16Chunk)
            }
            
            shouldOpen = lastVadResult

	    if lastVadResult != lastLoggedVadResult || gateOpen != lastLoggedGateOpen {
        	DebugTelemetry.capture.log("VAD [WebRTC] State Change: speechDetected=\(lastVadResult), gateOpen=\(gateOpen)")
        	lastLoggedVadResult = lastVadResult
         	lastLoggedGateOpen = gateOpen
	    }
            
        } else {
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

	    DebugTelemetry.capture.log("VAD [Legacy Envelope]: peak=\(peak), envelope=\(gateEnvelope), shouldOpen=\(shouldOpen)")
        }

        let closeThreshold: Float = 0.003

	let targetHangoverMS: Double = DebugFlags.useWebRTCVAD ? 1000.0 : 40.0
    
	let effectiveSampleRate: Double = 8000.0 
	let bufferDurationMS = (Double(samples.count) / effectiveSampleRate) * 1000.0
    
	let calculatedBuffers = bufferDurationMS > 0 ? Int(ceil(targetHangoverMS / bufferDurationMS)) : (DebugFlags.useWebRTCVAD ? 25 : 2)
	let holdBuffers = max(1, calculatedBuffers)

        let wasOpen = gateOpen

        if gateOpen {
            let shouldClose = DebugFlags.useWebRTCVAD ? !shouldOpen : (gateEnvelope < closeThreshold)
            
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

        let targetGain: Float = gateOpen ? 1.0 : 0.0

        if targetGain > gateGain {
            gateGain += (targetGain - gateGain) * 0.20
        } else {
            gateGain += (targetGain - gateGain) * 0.05
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
