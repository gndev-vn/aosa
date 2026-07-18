import 'package:flutter/material.dart';

Future<bool> showConfirmDeleteDialog(
  BuildContext context, {
  required String issuer,
  required String? accountLabel,
}) async {
  final cs = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.delete_outline_rounded, size: 28, color: cs.onErrorContainer),
            ),
            const SizedBox(height: 16),
            const Text('Delete Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              accountLabel != null
                  ? 'Remove $issuer ($accountLabel)? This cannot be undone.'
                  : 'Remove $issuer?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(false),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: cs.outlineVariant)),
                  child: Center(child: Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface))),
                ),
              )),
              const SizedBox(width: 12),
              Expanded(child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(true),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: cs.error),
                  child: Center(child: Text('Delete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onError))),
                ),
              )),
            ]),
          ],
        ),
      ),
    ),
  );
  return confirmed ?? false;
}
