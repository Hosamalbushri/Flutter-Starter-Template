/// Whether the app wires the Firebase *platform* (core, remote config,
/// messaging, performance) at startup.
///
/// Disabled by default so a checkout containing placeholder Firebase options
/// cannot send telemetry to an unintended project. Enable only after supplying
/// real native configuration with `--dart-define=FIREBASE_ENABLED=true` (or the
/// equivalent value in a `--dart-define-from-file` environment file).
const bool kFirebaseEnabled = bool.fromEnvironment(
  'FIREBASE_ENABLED',
  defaultValue: false,
);
