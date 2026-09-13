import 'package:aosa/data/repositories/otp_repository_impl.dart';
import 'package:aosa/presentation/providers/navigation_provider.dart';
import 'package:aosa/presentation/providers/otp_list_provider.dart';
import 'package:aosa/presentation/screens/edit_otp_screen.dart';
import 'package:aosa/presentation/screens/home_screen.dart';
import 'package:aosa/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationProvider);
    final repo = ref.watch(otpRepositoryProvider);

    final shadTheme = ShadTheme.of(context);
    final isDark = shadTheme.brightness == Brightness.dark;

    final screen = switch (nav.currentScreen) {
      AppScreen.home => const HomeScreen(),
      AppScreen.settings => const SettingsScreen(),
      AppScreen.editOtp => repo != null
          ? _buildEditScreen(ref, nav, repo)
          : const HomeScreen(),
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: shadTheme.colorScheme.background,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: shadTheme.colorScheme.background,
        body: PopScope(
          canPop: nav.currentScreen == AppScreen.home,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              ref.read(navigationProvider.notifier).goToHome();
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.02),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(nav.currentScreen),
              child: screen,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditScreen(
    WidgetRef ref,
    NavigationState nav,
    OtpRepositoryImpl repo,
  ) {
    final otpId = nav.editOtpId;
    if (otpId == null) return const HomeScreen();

    final accounts = ref.watch(otpListProvider);
    final match = accounts.where((e) => e.account.id == otpId);
    if (match.isEmpty) return const HomeScreen();

    return EditOtpScreen(
      repository: repo,
      account: match.first.account,
    );
  }
}
