// lib/config/test_flags.dart
//
// Set via `--dart-define=INTEGRATION_TEST=true` when launching the app for
// integration_test runs (see integration_test/app_test.dart and the CI
// workflow). Unlike `Platform.environment`, dart-define values are baked
// into the compiled app, so this is visible inside the on-device process
// started by `flutter test integration_test/... -d <device>` — where a
// host-side env var like FLUTTER_TEST is not.
const bool kIsIntegrationTest = bool.fromEnvironment('INTEGRATION_TEST');
