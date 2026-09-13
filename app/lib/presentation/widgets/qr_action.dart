import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class QrAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const QrAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ShadButton.outline(
      width: double.infinity,
      height: 48,
      onPressed: onPressed,
      leading: Icon(icon, size: 18, color: Colors.white),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
