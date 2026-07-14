// lib/config/test_flags.dart
//
// Set via `--dart-define=INTEGRATION_TEST=true` when launching the app for
// integration_test runs (see integration_test/helpers.dart and the CI
// workflow). Unlike `Platform.environment`, dart-define values are baked
// into the compiled app, so this is visible inside the on-device process
// started by `flutter test integration_test/... -d <device>` — where a
// host-side env var like FLUTTER_TEST is not.
const bool kIsIntegrationTest = bool.fromEnvironment('INTEGRATION_TEST');

/// Effective duration to use for a `flutter_animate` effect.
///
/// During integration tests, `pumpAndSettle` has to wait out every fade /
/// scale / slide in *real* wall-clock time — Android's system-level
/// "disable animations" setting only zeroes the OS animator scale, it has
/// no effect on flutter_animate's own Dart-side Tween timers. Collapsing
/// these to zero duration under [kIsIntegrationTest] removes that dead
/// time from CI without changing anything about the production UI.
Duration testAwareDuration(Duration normal) =>
    kIsIntegrationTest ? Duration.zero : normal;
