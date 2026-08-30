// lib/services/google_sign_in_singleton.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

/// Pure resolution of the compile-time Google sign-in client ids.
///
/// Kept separate from [GoogleSignInSingleton] so it is unit-testable without
/// touching a platform channel.
class GoogleSignInConfig {
  GoogleSignInConfig._();

  /// On web the web client id is used; on other platforms the server id is.
  /// Blank (unset via `--dart-define`) ids become null.
  static ({String? clientId, String? serverClientId}) resolve({
    required bool isWeb,
    required String webClientId,
    required String serverClientId,
  }) =>
      (
        clientId: isWeb ? (webClientId.isEmpty ? null : webClientId) : null,
        serverClientId:
            isWeb ? null : (serverClientId.isEmpty ? null : serverClientId),
      );
}

class GoogleSignInSingleton {
  GoogleSignInSingleton._();

  static GoogleSignIn get instance => GoogleSignIn.instance;

  static Future<void> initialize() async {
    const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    const serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

    final cfg = GoogleSignInConfig.resolve(
      isWeb: kIsWeb,
      webClientId: webClientId,
      serverClientId: serverClientId,
    );
    await instance.initialize(
      clientId: cfg.clientId,
      serverClientId: cfg.serverClientId,
    );
  }
}