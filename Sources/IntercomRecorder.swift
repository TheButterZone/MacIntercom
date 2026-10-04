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
import CoreAudio
import AudioToolbox

final class IntercomRecorder {
    private var audioFile: ExtAudioFileRef?
    private let lock = NSLock()
    private let queue = DispatchQueue(label: "com.thebutterzone.macintercom.recorder", qos: .utility)
    private(set) var isRecording = false
    private let sampleRate: Double = 48_000.0 // Universal locked sample rate

    private var localQueue: [Float] = []
    private var remoteQueue: [Float] = []

    func startRecording() -> Bool {
        lock.lock()
        if isRecording {
            lock.unlock()
            return true
        }

        localQueue.removeAll()
        remoteQueue.removeAll()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsPath.appendingPathComponent("Intercom_\(timestamp).wav")

        var streamDesc = AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked,
            mBytesPerPacket: 4, // 2 channels * 2 bytes per sample (16-bit)
            mFramesPerPacket: 1,
            mBytesPerFrame: 4,
            mChannelsPerFrame: 2, // Stereo: Ch 1 = Local, Ch 2 = Remote
            mBitsPerChannel: 16,
            mReserved: 0
        )

        var fileRef: ExtAudioFileRef?
        let status = ExtAudioFileCreateWithURL(
            fileURL as CFURL,
            kAudioFileWAVEType,
            &streamDesc,
            nil,
            AudioFileFlags.eraseFile.rawValue,
            &fileRef
        )

        guard status == noErr, let ref = fileRef else {
            Logger.error("Failed to create recording file: \(status)")
            lock.unlock()
            return false
        }

        let clientStatus = ExtAudioFileSetProperty(
            ref,
            kExtAudioFileProperty_ClientDataFormat,
            UInt32(MemoryLayout<AudioStreamBasicDescription>.size),
            &streamDesc
        )

        guard clientStatus == noErr else {
            Logger.error("Failed to set client audio format for recording: \(clientStatus)")
            ExtAudioFileDispose(ref)
            lock.unlock()
            return false
        }

        audioFile = ref
        isRecording = true
        lock.unlock()

        Logger.info("🔴 Started recording intercom session to: \(fileURL.path)")
        return true
    }

    func appendLocalSamples(_ samples: [Float]) {
        guard isRecording else { return }
        lock.lock()
        localQueue.append(contentsOf: samples)
        processQueuesLocked()
        lock.unlock()
    }

    func appendRemoteSamples(_ samples: [Float]) {
        guard isRecording else { return }
        lock.lock()
        remoteQueue.append(contentsOf: samples)
        processQueuesLocked()
        lock.unlock()
    }

    private func processQueuesLocked() {
        guard isRecording, let fileRef = audioFile else { return }

        let frameCount = min(localQueue.count, remoteQueue.count)
        guard frameCount > 0 else { return }

        let localChunk = Array(localQueue.prefix(frameCount))
        let remoteChunk = Array(remoteQueue.prefix(frameCount))

        localQueue.removeFirst(frameCount)
        remoteQueue.removeFirst(frameCount)

        queue.async {
            var interleavedBuffer = [Int16](repeating: 0, count: frameCount * 2)

            for i in 0..<frameCount {
                let localSample = max(-1.0, min(1.0, localChunk[i]))
                let remoteSample = max(-1.0, min(1.0, remoteChunk[i]))

                interleavedBuffer[i * 2]     = Int16(localSample * 32767.0)
                interleavedBuffer[i * 2 + 1] = Int16(remoteSample * 32767.0)
            }

            let byteSize = UInt32(interleavedBuffer.count * MemoryLayout<Int16>.size)

            interleavedBuffer.withUnsafeMutableBytes { rawBytes in
                var bufferList = AudioBufferList(
                    mNumberBuffers: 1,
                    mBuffers: CoreAudio.AudioBuffer(
                        mNumberChannels: 2,
                        mDataByteSize: byteSize,
                        mData: rawBytes.baseAddress
                    )
                )

                withUnsafeMutablePointer(to: &bufferList) { bufferListPtr in
                    let status = ExtAudioFileWrite(fileRef, UInt32(frameCount), bufferListPtr)
                    if status != noErr {
                        Logger.error("Failed to write audio buffer: \(status)")
                    }
                }
            }
        }
    }

    func stopRecording() {
        lock.lock()
        guard isRecording else {
            lock.unlock()
            return
        }
        isRecording = false

        if !localQueue.isEmpty || !remoteQueue.isEmpty {
            let frameCount = max(localQueue.count, remoteQueue.count)
            if frameCount > 0 {
                var localChunk = localQueue
                var remoteChunk = remoteQueue
                if localChunk.count < frameCount {
                    localChunk.append(contentsOf: [Float](repeating: 0, count: frameCount - localChunk.count))
                }
                if remoteChunk.count < frameCount {
                    remoteChunk.append(contentsOf: [Float](repeating: 0, count: frameCount - remoteChunk.count))
                }
                
                let ref = audioFile
                queue.async {
                    guard let ref = ref else { return }
                    var interleavedBuffer = [Int16](repeating: 0, count: frameCount * 2)
                    for i in 0..<frameCount {
                        let localSample = max(-1.0, min(1.0, localChunk[i]))
                        let remoteSample = max(-1.0, min(1.0, remoteChunk[i]))
                        interleavedBuffer[i * 2]     = Int16(localSample * 32767.0)
                        interleavedBuffer[i * 2 + 1] = Int16(remoteSample * 32767.0)
                    }

                    let byteSize = UInt32(interleavedBuffer.count * MemoryLayout<Int16>.size)

                    interleavedBuffer.withUnsafeMutableBytes { rawBytes in
                        var bufferList = AudioBufferList(
                            mNumberBuffers: 1,
                            mBuffers: CoreAudio.AudioBuffer(
                                mNumberChannels: 2,
                                mDataByteSize: byteSize,
                                mData: rawBytes.baseAddress
                            )
                        )
                        withUnsafeMutablePointer(to: &bufferList) { bufferListPtr in
                            _ = ExtAudioFileWrite(ref, UInt32(frameCount), bufferListPtr)
                        }
                    }
                }
            }
        }

        localQueue.removeAll()
        remoteQueue.removeAll()

        queue.sync {
            if let ref = self.audioFile {
                ExtAudioFileDispose(ref)
                self.audioFile = nil
            }
        }
        lock.unlock()
        Logger.info("⏹️ Intercom recording saved successfully.")
    }
}