import 'package:flutter/material.dart';

Widget buildGSIButton({
  required VoidCallback onPressed,
  required String label,
  bool isLoading = false,
}) {
  return ElevatedButton.icon(
    onPressed: isLoading ? null : onPressed,
    icon: const Icon(Icons.login_rounded),
    label: Text(label),
  );
}
