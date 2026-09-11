import 'dart:async';

import 'package:aosa/data/repositories/otp_repository_impl.dart';
import 'package:aosa/domain/entities/otp_account.dart';
import 'package:aosa/domain/entities/totp_code.dart';
import 'package:aosa/domain/repositories/otp_repository.dart';
import 'package:aosa/domain/usecases/totp_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_init_provider.dart';

final otpRepositoryProvider = Provider<OtpRepositoryImpl?>((ref) {
  final services = ref.watch(appInitProvider);
  if (services == null) return null;
  return services.otpRepository as OtpRepositoryImpl?;
});

class OtpCodeWithAccount {
  final OtpAccount account;
  final TotpCode code;

  OtpCodeWithAccount({required this.account, required this.code});
}

class OtpListNotifier extends StateNotifier<List<OtpCodeWithAccount>> {
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  StreamSubscription<List<OtpAccount>>? _repoSubscription;

  OtpListNotifier() : super([]);

  void setRepository(OtpRepository repo) {
    _repoSubscription = repo.watchAll().listen((accounts) {
      if (!_isRefreshing) {
        loadAccounts(accounts);
      }
    });
  }

  Future<void> loadAccounts(List<OtpAccount> accounts) async {
    final items = <OtpCodeWithAccount>[];
    for (final a in accounts) {
      final engine = TotpEngine(period: a.period, digits: a.digits, algorithm: a.algorithm);
      items.add(
        OtpCodeWithAccount(
          account: a,
          code: TotpCode(
            code: '------',
            timeLeft: engine.timeLeft,
            totalPeriod: a.period,
            algorithm: a.algorithm,
            digits: a.digits,
          ),
        ),
      );
    }
    state = items;
    await _generateAllCodes();
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      checkTokenRotation(now);
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _generateAllCodes() async {
    final updated = <OtpCodeWithAccount>[];
    for (final item in state) {
      final engine = TotpEngine(
        period: item.account.period,
        digits: item.account.digits,
        algorithm: item.account.algorithm,
      );
      String codeStr = '------';
      try {
        codeStr = await engine.generateCode(item.account.secretBase32);
      } catch (_) {}
      updated.add(
        OtpCodeWithAccount(
          account: item.account,
          code: TotpCode(
            code: codeStr,
            timeLeft: engine.timeLeft,
            totalPeriod: item.account.period,
            algorithm: item.account.algorithm,
            digits: item.account.digits,
          ),
        ),
      );
    }
    if (!mounted) return;
    state = updated;
  }

  void checkTokenRotation(int now) {
    if (_isRefreshing || state.isEmpty) return;

    final needsRegeneration = <int>[];
    for (int i = 0; i < state.length; i++) {
      final item = state[i];
      final timeLeft = item.account.period - (now % item.account.period);
      if (timeLeft == item.account.period) {
        needsRegeneration.add(i);
      }
    }

    if (needsRegeneration.isEmpty) {
      // Avoid mutating state if no code rolled over.
      // Progress indicators consume isolated totpTickerProvider.
      return;
    }

    _regenerateAndUpdate(needsRegeneration, now);
  }

  Future<void> _regenerateAndUpdate(List<int> indices, int now) async {
    _isRefreshing = true;
    final updated = [...state];

    for (final i in indices) {
      final item = state[i];
      final engine = TotpEngine(
        period: item.account.period,
        digits: item.account.digits,
        algorithm: item.account.algorithm,
      );
      try {
        final codeStr = await engine.generateCode(item.account.secretBase32);
        updated[i] = OtpCodeWithAccount(
          account: item.account,
          code: TotpCode(
            code: codeStr,
            timeLeft: item.account.period,
            totalPeriod: item.account.period,
            algorithm: item.account.algorithm,
            digits: item.account.digits,
          ),
        );
      } catch (_) {}
    }

    if (!mounted) {
      _isRefreshing = false;
      return;
    }
    state = updated;
    _isRefreshing = false;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _repoSubscription?.cancel();
    super.dispose();
  }
}

final otpListProvider = StateNotifierProvider<OtpListNotifier, List<OtpCodeWithAccount>>(
  (_) => OtpListNotifier(),
);
