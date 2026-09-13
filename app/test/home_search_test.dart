import 'package:aosa/core/theme/app_theme.dart';
import 'package:aosa/domain/entities/otp_account.dart';
import 'package:aosa/domain/entities/totp_code.dart';
import 'package:aosa/presentation/providers/otp_list_provider.dart';
import 'package:aosa/presentation/screens/home_screen.dart';
import 'package:aosa/presentation/widgets/home_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  final testAccounts = [
    OtpCodeWithAccount(
      account: OtpAccount(
        id: 'acc-1',
        issuer: 'GitHub',
        accountLabel: 'octocat@github.com',
        secretBase32: 'JBSWY3DPEHPK3PXP',
      ),
      code: const TotpCode(
        code: '123456',
        timeLeft: 30,
        totalPeriod: 30,
        algorithm: 'SHA1',
        digits: 6,
      ),
    ),
    OtpCodeWithAccount(
      account: OtpAccount(
        id: 'acc-2',
        issuer: 'Google',
        accountLabel: 'user@gmail.com',
        secretBase32: 'GEZDGNBVGY3TQOJQ',
      ),
      code: const TotpCode(
        code: '654321',
        timeLeft: 30,
        totalPeriod: 30,
        algorithm: 'SHA1',
        digits: 6,
      ),
    ),
  ];

  group('HomeScreen Search Filtering Tests', () {
    testWidgets('filters accounts in real-time based on search input', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            otpListProvider.overrideWith((ref) {
              final notifier = OtpListNotifier();
              notifier.state = testAccounts;
              return notifier;
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(seedColor: Colors.blue),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);

      // Enter search query "git"
      await tester.enterText(find.byType(EditableText), 'git');
      await tester.pump();

      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('Google'), findsNothing);

      // Clear search query via clear button
      final clearButton = find.byIcon(LucideIcons.x);
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pump();

      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);

      // Search with no matches displays HomeEmptyState
      await tester.enterText(find.byType(EditableText), 'xyz-not-found');
      await tester.pump();

      expect(find.text('GitHub'), findsNothing);
      expect(find.text('Google'), findsNothing);
      expect(find.byType(HomeEmptyState), findsOneWidget);

      // Clean up repeat animations
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
