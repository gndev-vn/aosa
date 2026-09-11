import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/platform/app_platform.dart';
import 'core/theme/app_theme.dart';
import 'domain/entities/app_settings.dart';
import 'presentation/providers/app_init_provider.dart';
import 'presentation/providers/app_lock_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/otp_list_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/lock_screen.dart';
import 'presentation/widgets/app_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppPlatformUtil.isMobile) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  final container = ProviderContainer();
  await container.read(appInitProvider.notifier).initialize();
  await container.read(settingsProvider.notifier).load();
  await container.read(authProvider.notifier).checkSession();
  final services = container.read(appInitProvider);

  if (services != null) {
    container.read(otpListProvider.notifier).setRepository(services.otpRepository);
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AosaApp(),
    ),
  );
}

class AosaApp extends ConsumerStatefulWidget {
  const AosaApp({super.key});

  @override
  ConsumerState<AosaApp> createState() => _AosaAppState();
}

class _AosaAppState extends ConsumerState<AosaApp> with WidgetsBindingObserver {
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockTimer?.cancel();
    super.dispose();
  }

  Duration _lockDelay(AutoLockTimeout timeout) {
    return switch (timeout) {
      AutoLockTimeout.immediate => Duration.zero,
      AutoLockTimeout.seconds30 => const Duration(seconds: 30),
      AutoLockTimeout.minute1 => const Duration(minutes: 1),
      AutoLockTimeout.minutes5 => const Duration(minutes: 5),
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lock = ref.read(appLockProvider.notifier);
    final settings = ref.read(settingsProvider);

    if (state == AppLifecycleState.paused && settings.pinEnabled) {
      final delay = _lockDelay(settings.autoLockTimeout);
      if (delay == Duration.zero) {
        lock.lock();
      } else {
        _lockTimer?.cancel();
        _lockTimer = Timer(delay, () {
          if (mounted) {
            ref.read(appLockProvider.notifier).lock();
          }
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _lockTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockProvider);
    final settings = ref.watch(settingsProvider);
    final seedColor = Color(settings.seedColor);
    final themeMode = switch (settings.themeMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };

    final showApp = lockState.status == AppLockStatus.unlocked || !settings.pinEnabled;

    return MaterialApp(
      title: 'AOSA',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(seedColor: seedColor),
      darkTheme: AppTheme.dark(seedColor: seedColor),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),),
            child: FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
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
          key: ValueKey(showApp),
          child: showApp ? const AppScaffold() : const LockScreen(),
        ),
      ),
    );
  }
}
