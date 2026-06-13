import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aosa/data/repositories/otp_repository_impl.dart';
import 'package:aosa/presentation/providers/navigation_provider.dart';
import 'package:aosa/presentation/providers/otp_list_provider.dart';
import 'package:aosa/presentation/screens/edit_otp_screen.dart';
import 'package:aosa/presentation/screens/home_screen.dart';
import 'package:aosa/presentation/screens/settings_screen.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationProvider);
    final repo = ref.watch(otpRepositoryProvider);

    final screen = switch (nav.currentScreen) {
      AppScreen.home => const HomeScreen(),
      AppScreen.settings => const SettingsScreen(),
      AppScreen.editOtp => _buildEditScreen(ref, nav, repo),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.93, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
              ),
              child: child,
            ),
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(nav.currentScreen),
        child: screen,
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
