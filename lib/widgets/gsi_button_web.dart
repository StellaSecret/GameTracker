import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web_plugin;

Widget buildGSIButton({
  required VoidCallback onPressed,
  required String label,
  bool isLoading = false,
}) {
  final plugin = GoogleSignInPlatform.instance as web_plugin.GoogleSignInPlugin;
  return plugin.renderButton(
    configuration: web_plugin.GSIButtonConfiguration(
      type: web_plugin.GSIButtonType.standard,
      shape: web_plugin.GSIButtonShape.rectangular,
      theme: web_plugin.GSIButtonTheme.outline,
    ),
  );
}
