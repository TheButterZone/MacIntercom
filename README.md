# MacIntercom

Bidirectional computer ↔ Bluetooth audio routing for macOS.

> Development status: early release. Hardware compatibility and audio pipeline improvements are ongoing.

## Features:

- Bidirectional computer ↔ Bluetooth audio routing
- Bluetooth microphone capture
- Bluetooth speaker output
- Test tone diagnostics
- Audio route status logging

## Installation (macOS)

MacIntercom is distributed as a pre-compiled, ad-hoc signed universal binary. 

Because it is signed ad-hoc (rather than using an official Apple Developer account), macOS will block its initial execution with a security prompt.

**To run the binary immediately:**
1. Download the `macintercom-macos-universal-...zip` file from the latest Release and extract it.
2. Open your terminal and navigate to the folder containing the extracted file.
3. Strip the web-download quarantine flag by running:
   ```
   xattr -d com.apple.quarantine ./macintercom
   ```
3. Run the application normally:
   ```
   ./macintercom
   ```

## Modes

- Media-aware mode (default when running ./macintercom) — intercom automatically yields to media playback.
- Standalone mode (run ./macintercom --s) intercom ignores media playback and stays active continuously until Ctrl-C.
- Test tone mode (run ./macintercom --t) intercom simultaneously plays 220 Hz tone through computer output & 440 Hz tone through Bluetooth speaker.

## Roadmap

  - Dynamic hardware format adaptation
  - Production-grade real-time audio buffer improvements
  - High-quality streaming resampling

## Licensing

MacIntercom is free and open-source software licensed under the GNU General Public License v3.0.

You are free to use, modify, and redistribute MacIntercom under the terms of the GPL-3.0 license.

For organizations that require proprietary integration, closed-source distribution, commercial hardware bundling, custom development, or dedicated support, commercial licensing options are available.

Contact: tbz.one/contact