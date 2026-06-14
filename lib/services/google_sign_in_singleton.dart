import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInSingleton {
  GoogleSignInSingleton._();

  static GoogleSignIn get instance => GoogleSignIn.instance;

  static Future<void> initialize() async {
    const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    const serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

    await instance.initialize(
      clientId: kIsWeb ? webClientId : null,
      serverClientId: kIsWeb ? null : serverClientId,
    );
  }
}
