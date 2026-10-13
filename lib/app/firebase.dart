/// Whether the app wires the Firebase *platform* (core, remote config,
/// messaging, performance) at startup.
///
/// `true` by default. `fst create --no-firebase` flips this to `false` and
/// strips the native Firebase config, so the app builds and runs without a
/// Firebase project. Tracking (analytics, crash reporting, and performance) is
/// selected independently via the `// fst:analytics-impl`, `// fst:crash-impl`,
/// and `// fst:performance-impl` bindings in the `analytics`, `app_platform`,
/// and `network` packages.
const bool kFirebaseEnabled = true;
