import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aosa/data/repositories/otp_repository_impl.dart';
import 'package:aosa/domain/entities/otp_account.dart';
import 'package:aosa/domain/entities/totp_code.dart';
import 'package:aosa/domain/repositories/otp_repository.dart';
import 'package:aosa/domain/usecases/totp_engine.dart';
import 'app_init_provider.dart';

final otpRepositoryProvider = Provider<OtpRepositoryImpl>((ref) {
  final services = ref.watch(appInitProvider);
  if (services == null) {
    throw StateError('App not initialized — cannot access repository');
  }
  return services.otpRepository as OtpRepositoryImpl;
});

class OtpCodeWithAccount {
  final OtpAccount account;
  final TotpCode code;

  OtpCodeWithAccount({required this.account, required this.code});
}

class OtpListNotifier extends StateNotifier<List<OtpCodeWithAccount>> {
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  OtpRepository? _repo;
  StreamSubscription? _repoSubscription;

  OtpListNotifier() : super([]);

  void setRepository(OtpRepository repo) {
    _repo = repo;
    _repoSubscription = repo.watchAll().listen((accounts) {
      if (!_isRefreshing) {
        loadAccounts(accounts);
      }
    });
  }

  void loadAccounts(List<OtpAccount> accounts) {
    final items = <OtpCodeWithAccount>[];
    for (final a in accounts) {
      final engine = TotpEngine(period: a.period, digits: a.digits, algorithm: a.algorithm);
      items.add(OtpCodeWithAccount(
        account: a,
        code: TotpCode(
          code: '------',
          timeLeft: engine.timeLeft,
          totalPeriod: a.period,
          algorithm: a.algorithm,
          digits: a.digits,
        ),
      ));
    }
    state = items;
    _generateAllCodes();
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshCodes());
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _generateAllCodes() async {
    for (int i = 0; i < state.length; i++) {
      final item = state[i];
      final engine = TotpEngine(
        period: item.account.period,
        digits: item.account.digits,
        algorithm: item.account.algorithm,
      );
      try {
        final codeStr = await engine.generateCode(item.account.secretBase32);
        final updated = [...state];
        updated[i] = OtpCodeWithAccount(
          account: item.account,
          code: TotpCode(
            code: codeStr,
            timeLeft: engine.timeLeft,
            totalPeriod: item.account.period,
            algorithm: item.account.algorithm,
            digits: item.account.digits,
          ),
        );
        state = updated;
      } catch (_) {}
    }
  }

  void _refreshCodes() {
    if (_isRefreshing || state.isEmpty) return;
    _isRefreshing = true;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final needsRegeneration = <int>[];

    for (int i = 0; i < state.length; i++) {
      final item = state[i];
      final timeLeft = item.account.period - (now % item.account.period);
      final adjustedTimeLeft = timeLeft == 0 ? item.account.period : timeLeft;

      if (adjustedTimeLeft == item.account.period) {
        needsRegeneration.add(i);
      }
    }

    if (needsRegeneration.isEmpty) {
      _updateTimeLeftOnly(now);
      _isRefreshing = false;
      return;
    }

    _regenerateAndUpdate(needsRegeneration, now);
  }

  void _updateTimeLeftOnly(int now) {
    state = [
      for (final item in state)
        OtpCodeWithAccount(
          account: item.account,
          code: TotpCode(
            code: item.code.code,
            timeLeft: _calcTimeLeft(item.account.period, now),
            totalPeriod: item.account.period,
            algorithm: item.account.algorithm,
            digits: item.account.digits,
          ),
        ),
    ];
    _isRefreshing = false;
  }

  Future<void> _regenerateAndUpdate(List<int> indices, int now) async {
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
            timeLeft: _calcTimeLeft(item.account.period, now),
            totalPeriod: item.account.period,
            algorithm: item.account.algorithm,
            digits: item.account.digits,
          ),
        );
      } catch (_) {
        updated[i] = OtpCodeWithAccount(
          account: item.account,
          code: TotpCode(
            code: item.code.code,
            timeLeft: _calcTimeLeft(item.account.period, now),
            totalPeriod: item.account.period,
            algorithm: item.account.algorithm,
            digits: item.account.digits,
          ),
        );
      }
    }

    state = updated;
    _isRefreshing = false;
  }

  int _calcTimeLeft(int period, int now) {
    final remaining = period - (now % period);
    return remaining == 0 ? period : remaining;
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
