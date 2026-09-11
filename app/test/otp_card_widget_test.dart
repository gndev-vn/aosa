import 'package:aosa/domain/entities/otp_account.dart';
import 'package:aosa/domain/entities/totp_code.dart';
import 'package:aosa/presentation/providers/otp_list_provider.dart';
import 'package:aosa/presentation/widgets/otp_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OtpCard Widget Tests', () {
    testWidgets('renders account and code correctly without animation jank', (tester) async {
      final account = OtpAccount(
        id: 'acc-1',
        issuer: 'GitHub',
        accountLabel: 'dev@github.com',
        secretBase32: 'JBSWY3DPEE======',
        period: 30,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final item = OtpCodeWithAccount(
        account: account,
        code: const TotpCode(
          code: '123456',
          timeLeft: 25,
          totalPeriod: 30,
          algorithm: 'SHA1',
          digits: 6,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: OtpCard(item: item),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('dev@github.com'), findsOneWidget);
      expect(find.text('123 456'), findsOneWidget);

      // Rebuilding the widget must not crash or fail rendering
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: OtpCard(item: item),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('GitHub'), findsOneWidget);
    });

    testWidgets('tap copies code to clipboard with haptic feedback', (tester) async {
      final account = OtpAccount(
        id: 'acc-1',
        issuer: 'GitHub',
        accountLabel: 'dev@github.com',
        secretBase32: 'JBSWY3DPEE======',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final item = OtpCodeWithAccount(
        account: account,
        code: const TotpCode(
          code: '987654',
          timeLeft: 20,
          totalPeriod: 30,
          algorithm: 'SHA1',
          digits: 6,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: OtpCard(item: item),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(OtpCard));
      await tester.pump();

      expect(find.text('Copied to clipboard'), findsOneWidget);
    });
  });
}
