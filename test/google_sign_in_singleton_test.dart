// Unit tests for the pure GoogleSignInConfig resolver. initialize() itself
// talks to GoogleSignIn.instance (a platform channel) and is exempt.
// Run with: flutter test test/google_sign_in_singleton_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:game_tracker/services/google_sign_in_singleton.dart';

void main() {
  test('web uses the web client id and no server id', () {
    final cfg = GoogleSignInConfig.resolve(
      isWeb: true,
      webClientId: 'web-id',
      serverClientId: 'server-id',
    );
    expect(cfg, (clientId: 'web-id', serverClientId: null));
  });

  test('web with a blank web client id disables sign-in', () {
    final cfg = GoogleSignInConfig.resolve(
      isWeb: true,
      webClientId: '',
      serverClientId: 'server-id',
    );
    expect(cfg, (clientId: null, serverClientId: null));
  });

  test('native uses the server client id and no web id', () {
    final cfg = GoogleSignInConfig.resolve(
      isWeb: false,
      webClientId: 'web-id',
      serverClientId: 'server-id',
    );
    expect(cfg, (clientId: null, serverClientId: 'server-id'));
  });

  test('native with a blank server client id disables sign-in', () {
    final cfg = GoogleSignInConfig.resolve(
      isWeb: false,
      webClientId: 'web-id',
      serverClientId: '',
    );
    expect(cfg, (clientId: null, serverClientId: null));
  });
}