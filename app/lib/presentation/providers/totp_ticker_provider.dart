import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A lightweight, synchronized ticker that emits the current Unix epoch second.
/// Subscribed widgets (such as countdown progress bars) only rebuild themselves,
/// rather than triggering full-list or parent screen-level rebuilds.
final totpTickerProvider = StreamProvider.autoDispose<int>((ref) {
  final controller = StreamController<int>();

  // Emit initial second immediately
  controller.add(DateTime.now().millisecondsSinceEpoch ~/ 1000);

  final timer = Timer.periodic(const Duration(seconds: 1), (_) {
    if (!controller.isClosed) {
      controller.add(DateTime.now().millisecondsSinceEpoch ~/ 1000);
    }
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Computes seconds remaining until the next TOTP token rotation.
int calculateTimeLeft(int period, int currentEpochSeconds) {
  final remaining = period - (currentEpochSeconds % period);
  return remaining == 0 ? period : remaining;
}

/// Computes the countdown progress fraction (1.0 = freshly generated, approaching 0.0).
double calculateProgressFraction(int period, int currentEpochSeconds) {
  final timeLeft = calculateTimeLeft(period, currentEpochSeconds);
  return timeLeft / period;
}
