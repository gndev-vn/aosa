import 'package:aosa/domain/entities/otp_account.dart';
import 'package:aosa/presentation/providers/otp_list_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OtpListNotifier Performance & Stability', () {
    test('loadAccounts initializes state with accounts and codes', () async {
      final notifier = OtpListNotifier();
      final account = OtpAccount(
        id: 'acc-1',
        issuer: 'GitHub',
        accountLabel: 'dev@github.com',
        secretBase32: 'JBSWY3DPEE======',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await notifier.loadAccounts([account]);
      expect(notifier.state.length, 1);
      expect(notifier.state.first.account.issuer, 'GitHub');

      // Wait for code generation to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(notifier.state.first.code.code, isNotEmpty);
      expect(notifier.state.first.code.code, isNot('------'));

      notifier.dispose();
    });

    test('state reference remains stable during non-rollover ticks', () async {
      final notifier = OtpListNotifier();
      final account = OtpAccount(
        id: 'acc-1',
        issuer: 'Google',
        accountLabel: 'user@gmail.com',
        secretBase32: 'JBSWY3DPEE======',
        period: 30,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await notifier.loadAccounts([account]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final initialState = notifier.state;
      // Trigger a tick check where no code needs regeneration (e.g. 15s into a 30s period)
      notifier.checkTokenRotation(15);

      // State reference must not be needlessly reallocated if no token rotated
      expect(identical(notifier.state, initialState), isTrue);

      notifier.dispose();
    });
  });
}
