import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLockStatus { locked, unlocking, unlocked }

class AppLockState {
  final AppLockStatus status;
  final int failedAttempts;
  final bool biometricAvailable;
  final bool pinEnabled;
  final DateTime? cooldownUntil;

  const AppLockState({
    this.status = AppLockStatus.locked,
    this.failedAttempts = 0,
    this.biometricAvailable = false,
    this.pinEnabled = false,
    this.cooldownUntil,
  });

  AppLockState copyWith({
    AppLockStatus? status,
    int? failedAttempts,
    bool? biometricAvailable,
    bool? pinEnabled,
    DateTime? cooldownUntil,
  }) {
    return AppLockState(
      status: status ?? this.status,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      cooldownUntil: cooldownUntil ?? this.cooldownUntil,
    );
  }
}

class AppLockNotifier extends Notifier<AppLockState> {
  @override
  AppLockState build() => const AppLockState();

  void unlock() => state = state.copyWith(status: AppLockStatus.unlocked);

  void lock() => state = state.copyWith(status: AppLockStatus.locked);

  void recordFailedAttempt() {
    final attempts = state.failedAttempts + 1;
    if (attempts >= 5) {
      final cooldown = DateTime.now().add(
        Duration(seconds: 30 * (attempts - 4)),
      );
      state = state.copyWith(
        failedAttempts: attempts,
        cooldownUntil: cooldown,
      );
    } else {
      state = state.copyWith(failedAttempts: attempts);
    }
  }

  void setBiometricAvailable(bool available) {
    state = state.copyWith(biometricAvailable: available);
  }

  void setPinEnabled(bool enabled) {
    state = state.copyWith(pinEnabled: enabled);
  }
}

final appLockProvider = NotifierProvider<AppLockNotifier, AppLockState>(
  AppLockNotifier.new,
);
