import 'package:flutter/material.dart';

class AosaActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme color;
  final VoidCallback onTap;

  const AosaActionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color.onPrimaryContainer),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
