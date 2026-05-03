// Instance unique de GoogleSignIn partagée entre Drive et Firebase Auth.
// Google Sign-In ne supporte qu'une seule instance active par app —
// avoir deux instances cause des conflits de callback d'activité Android.

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class GoogleSignInSingleton {
  GoogleSignInSingleton._();

  static final GoogleSignIn instance = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      drive.DriveApi.driveAppdataScope,
    ],
  );
}
