# MacIntercom

Bidirectional computer ↔ Bluetooth audio routing for macOS.

> Development status: early release. Hardware compatibility and audio pipeline improvements are ongoing.

## Features

- Bidirectional computer ↔ Bluetooth audio routing
- Automatic hardware format detection
- Integrated Bluetooth microphone support
- USB & analog microphone support
- Optional media-aware operation
- Standalone always-on intercom mode
- Low-latency streaming audio pipeline
- Integrated AGC and hysteresis noise gate
- Test tone diagnostics

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

## Running

- Media-aware mode (default when running ./macintercom) — intercom automatically yields to media playback.
- Standalone mode (run ./macintercom --s) intercom ignores media playback and stays active continuously until Ctrl-C.
- Test tone mode (run ./macintercom --t) intercom simultaneously plays 220 Hz tone through computer output & 440 Hz tone through Bluetooth speaker.

## Current status

Current development focuses on:

- improving sample-rate conversion
- preparing optional WebRTC Voice Activity Detection
- stabilizing the 0.1.x series before GUI work begins

## Roadmap

v0.1.7
- Higher-quality sample-rate conversion

v0.1.8
- Optional WebRTC Voice Activity Detection

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

- Bluetooth speaker with integrated microphone (HFP)

Computer Inputs

- USB UAC microphone
- 3.5 mm analog lavalier microphone (battery-powered)
- Mixer line input (48V-powered & unpowered microphones)

Computer Outputs

- 3.5 mm analog headphone/line level out
- Soundflower v2 (virtual audio output)

## Licensing

MacIntercom is free and open-source software licensed under the GNU General Public License v3.0.

You are free to use, modify, and redistribute MacIntercom under the terms of the GPL-3.0 license.

Organizations requiring proprietary integration, closed-source distribution, commercial hardware bundling, custom development, or dedicated support may contact the author regarding commercial licensing.

Contact: tbz.one/contact