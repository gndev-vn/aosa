import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppScreen { home, settings, editOtp }

class NavigationState {
  final AppScreen currentScreen;
  final String? editOtpId;

  const NavigationState({
    this.currentScreen = AppScreen.home,
    this.editOtpId,
  });
}

class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(const NavigationState());

  void goToHome() => state = const NavigationState(currentScreen: AppScreen.home);
  void goToSettings() => state = const NavigationState(currentScreen: AppScreen.settings);
  void goToEditOtp(String id) => state = NavigationState(
    currentScreen: AppScreen.editOtp,
    editOtpId: id,
  );
}

final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>(
  (_) => NavigationNotifier(),
);
