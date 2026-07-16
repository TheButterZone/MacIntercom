# MediaRemote Findings

## Confirmed

- Loading MediaRemote.framework changes Moo play/pause behavior.
- Effect disappears immediately when app exits.
- Polling is NOT the cause.
- Standalone probe can read playback state.
- bluetoothaudiod is the sender of media key events.
- mediaremoted receives commands from bluetoothaudiod.
