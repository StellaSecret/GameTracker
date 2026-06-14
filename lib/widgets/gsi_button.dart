import 'package:flutter/material.dart';
import 'gsi_button_stub.dart'
    if (dart.library.js_interop) 'gsi_button_web.dart' as impl;

class GSIButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final bool isLoading;

  const GSIButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return impl.buildGSIButton(
      onPressed: onPressed,
      label: label,
      isLoading: isLoading,
    );
  }
}
