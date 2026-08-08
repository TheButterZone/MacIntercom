# MacIntercom

Bidirectional computer ↔ Bluetooth audio routing for macOS.

> Development status: early release. Hardware compatibility and audio pipeline improvements are ongoing.

## Features

- Bidirectional computer ↔ Bluetooth audio routing
- Automatic hardware format detection
- Integrated Bluetooth microphone support
- USB & analog microphone support
- Media-aware operation (enabled by default)
- Optional standalone always-on intercom mode
- Optional Software-Defined Radio (SDR) dual-method squelch mode with smart passive CTCSS tone scanner for on-the-fly frequency identification & switching
- Test tone diagnostics
- Low-latency, high-quality streaming audio pipeline
- Integrated AGC and WebRTC Voice Activity Detection (VAD)
   * WebRTC VAD enabled by default for intelligent voice-gating
   * Replaces legacy envelope follower (toggleable via `DebugFlags`) to significantly reduce false triggers from room noise
   * Lightweight, zero external dependency footprint

## Requirements

- macOS Catalina (10.15) or later
- Bluetooth HFP/HSP audio device
- Microphone permission granted to Terminal (or the GUI app in future releases)

## Installation (macOS)

MacIntercom is distributed as a pre-compiled, ad-hoc signed universal binary. 

Because it is signed ad-hoc (rather than using an official Apple Developer account), macOS will block its initial execution with a security prompt.

**To run the binary immediately:**
1. Download the `macintercom-macos-universal-...zip` file from the latest Release and extract it.
2. Open your terminal and navigate to the folder containing the extracted file.
3. Remove the macOS quarantine attribute by running:
   ```
   xattr -d com.apple.quarantine ./macintercom
   ```
3. Run the application normally:
   ```
   ./macintercom
   ```
## Running MacIntercom

MacIntercom supports several operation modes depending on how you want to handle media integration, test tones, or Software-Defined Radio (SDR) inputs.

* **Media-Aware Mode (Default):** Run `./macintercom`. The intercom automatically yields to media playback, pausing/resuming media when toggled.
* **Standalone Mode:** Run `./macintercom --s`. The intercom ignores media playback and stays active continuously until closed with Ctrl-C.
* **SDR Squelch Mode:** Run `./macintercom --sdr`. Mutes the Bluetooth microphone return path for SDR inputs (e.g., routed via Soundflower), supporting two squelch methods:
  * **WebRTC VAD & Passive Scanner (Default):** Automatically detects human voice activity in the noise floor to open the gate. While running, a passive, zero-latency scanner continuously evaluates the audio and prints detected sub-audible CTCSS tones to the terminal & Mac Menu Bar dropdown.
    * *Interactive Hotkey:* In terminal, pressing Return instantly locks your squelch to the last detected tone (disabling VAD). Pressing Return again while a new tone is detected hot-swaps the lock to the new tone. Pressing Esc releases the lock entirely.
    * *Mac Menu Bar:* Click ⩛ when it appears while MacIntercom is running, then lock & unlock squelch.
  * **CTCSS Tone Squelch:** Pass `-tone <frequency>` (e.g., `./macintercom --sdr -tone 100.0`) to disable VAD and the scanner, and enforce strict, non-interactive tone squelch startup parameters.
* **Test Tone Mode:** Run `./macintercom --t`. Simultaneously plays a 220 Hz tone through the computer output and a 440 Hz tone through the Bluetooth speaker.

## Notes on Audio Quality

* **Universal 48 kHz Sample Rate:** To ensure the cleanest audio pipeline and lowest latency, set all active input and output devices (USB microphones, Line-In, Line-Out, and virtual routing tools like Soundflower) to a fixed **48 kHz** sample rate in macOS **Audio MIDI Setup**.

* **Bluetooth and SDR Mode:** When running `macintercom` in standard intercom mode, macOS forces Bluetooth speakers with integrated microphones, and headsets, into a lower-quality telephony profile (HFP) to use the microphone. However, because `--sdr` mode uses a virtual system input instead of your Bluetooth mic, you can route the output to any Bluetooth speaker or headset and it will remain in crisp, full-fidelity A2DP (e.g., 32-bit/48kHz).

---

## Current status

Current development focuses on:

- stabilizing the 0.1.x series before GUI work begins

## Roadmap

v0.1.9
- Stabilization and regression testing

v0.2
- GUI
- Device selection
- Runtime settings
- PA Mode

## Future Ideas

- Multiple simultaneous Bluetooth endpoints
- Network intercom
- Push-to-talk over keyboard
- Audio recording
- Optional echo cancellation backend
- Optional AUVoiceProcessingIO backend
- MacPorts & Homebrew packages

## Tested Hardware

Bluetooth

- Bluetooth speaker with integrated microphone (HFP in Media-Aware & Standalone Modes, A2DP in SDR Squelch Mode)

Computer Inputs

- USB UAC microphone
- 3.5 mm analog lavalier microphone (battery-powered)
- Mixer line input (48V-powered & unpowered microphones)
- [Soundflower v2.0b2](https://github.com/mattingalls/soundflower)
 

Computer Outputs

- 3.5 mm analog headphone/line level out
- [Soundflower v2.0b2](https://github.com/mattingalls/soundflower)

## Licensing

MacIntercom is free and open-source software licensed under the GNU General Public License v3.0.

You are free to use, modify, and redistribute MacIntercom under the terms of the GPL-3.0 license.

Organizations requiring proprietary integration, closed-source distribution, commercial hardware bundling, custom development, or dedicated support may contact the author regarding commercial licensing.

Contact: tbz.one/contact

### Third-Party Components
MacIntercom incorporates Voice Activity Detection (VAD) algorithms from the WebRTC project. Please refer to the [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md) file for complete copyright notices and redistribution terms.