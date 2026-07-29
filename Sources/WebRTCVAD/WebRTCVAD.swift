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

final class WebRTCVAD {
    private var handle: OpaquePointer?

    init(mode: Int = 2) {
        if let ptr = WebRtcVad_Create() {
            self.handle = ptr
            if WebRtcVad_Init(self.handle) != 0 {
                WebRtcVad_Free(self.handle)
                self.handle = nil
            } else {
                _ = WebRtcVad_set_mode(self.handle, Int32(mode))
            }
        }
    }

    deinit {
        if let handle = handle {
            WebRtcVad_Free(handle)
        }
    }

    func isSpeech(_ samples: [Int16]) -> Bool {
        guard let handle = handle else { return false }
        
        let sampleRate: Int32 = 8000
        
        let result = samples.withUnsafeBufferPointer { buffer in
            WebRtcVad_Process(handle, sampleRate, buffer.baseAddress, samples.count)
        }
        
        return result == 1
    }
}