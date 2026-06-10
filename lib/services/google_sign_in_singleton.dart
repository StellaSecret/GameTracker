import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInSingleton {
  GoogleSignInSingleton._();

  static GoogleSignIn get instance => GoogleSignIn.instance;

  static Future<void> initialize() async {
    await instance.initialize();
  }
}
