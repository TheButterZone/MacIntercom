# MediaRemote Findings

## Confirmed

- Loading MediaRemote.framework changes Moo play/pause behavior.
- Effect disappears immediately when app exits.
- Polling is NOT the cause.
- Standalone probe can read playback state.
- bluetoothaudiod is the sender of media key events.
- mediaremoted receives commands from bluetoothaudiod.

## Async & State Synchronization Insights

- **`MRMediaRemoteGetNowPlayingApplicationIsPlaying` is strictly asynchronous:**
  - Invoking it on `.main` queue without synchronization leads to startup race conditions where the app defaults to `PAUSED` before the actual state (`PLAYING`) arrives milliseconds later.
  - To obtain a synchronous startup state, query the symbol on `DispatchQueue.global()` and hold execution briefly with `DispatchSemaphore(value: 0)`.
  - **Deadlock Warning:** Requesting the callback on `.main` queue while calling `.wait()` on the main thread will cause a main-thread deadlock.

- **Controller Lifecycle & Callback Wiring:**
  - Triggering `applyMuteState()` inside `ConversationController.init()` creates a race condition because callback closures (such as `onMuteStateChanged`) are assigned *after* instantiation in `main.swift`.
  - Initial state sync must be decoupled into a dedicated method (e.g., `syncInitialState()`) and called explicitly after all delegate closures are wired up.

- **Main Thread Execution Order:**
  - `MediaRemoteObserver.start()` must execute before any main-thread blocking operations (such as `DispatchGroup.wait()` for audio engine capture callbacks). Otherwise, state polling is delayed until the startup group times out.

## macOS TCC & System Behaviors

- **Permission Persistence (TCC):**
  - Once microphone permissions are explicitly revoked or unchecked in macOS System Settings, subsequent calls to `AVCaptureDevice.requestAccess(for: .audio)` instantly evaluate to `false` without triggering a system prompt.
  - Resetting this state requires manual re-checking in **System Settings > Privacy & Security > Microphone** or executing `tccutil reset Microphone` in Terminal.
  - Setting `NSApplication.shared.setActivationPolicy(.accessory)` at the very entry point of `main.swift` ensures the process correctly registers with macOS prior to requesting system access.