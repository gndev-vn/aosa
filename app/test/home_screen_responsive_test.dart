import 'package:aosa/core/theme/app_theme.dart';
import 'package:aosa/domain/entities/app_settings.dart';
import 'package:aosa/presentation/providers/settings_provider.dart';
import 'package:aosa/presentation/screens/home_screen.dart';
import 'package:aosa/presentation/widgets/confirm_delete_dialog.dart';
import 'package:aosa/presentation/widgets/confirmation_bottom_sheet.dart';
import 'package:aosa/presentation/widgets/option_picker.dart';
import 'package:aosa/presentation/widgets/settings_helpers.dart';
import 'package:aosa/presentation/widgets/standard_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestSettingsNotifier extends SettingsNotifier {
  _TestSettingsNotifier(AppSettings initial) : super() {
    state = initial;
  }
}

void main() {
  group('HomeScreen Responsive Layout Tests', () {
    testWidgets('renders cleanly on mobile viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('AOSA'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Clean up repeat animations
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('constrains width on wide desktop viewport to 640px max', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('AOSA'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Verify ConstrainedBox with maxWidth: 640 is present
      final constrainedBoxFinder = find.byWidgetPredicate(
        (w) => w is ConstrainedBox && w.constraints.maxWidth == 640,
      );
      expect(constrainedBoxFinder, findsAtLeastNWidgets(1));

      // Clean up repeat animations
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('StandardBottomSheet enforces maxWidth: 640 constraint on desktop', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StandardBottomSheet(
              title: 'Add Account',
              child: Text('Sheet Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ADD ACCOUNT'), findsOneWidget);
      expect(find.text('Sheet Content'), findsOneWidget);

      final constrainedBoxFinder = find.byWidgetPredicate(
        (w) => w is ConstrainedBox && w.constraints.maxWidth == 640,
      );
      expect(constrainedBoxFinder, findsOneWidget);
    });

    testWidgets('showSlideBottomSheet on wide foldable/tablet device hugs intrinsic content height at bottom without top void', (tester) async {
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: Scaffold(
            body: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  showSlideBottomSheet<void>(
                    context,
                    builder: (_) => const StandardBottomSheet(
                      title: 'Add Account',
                      child: SizedBox(height: 120, child: Text('Sheet Content')),
                    ),
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('ADD ACCOUNT'), findsOneWidget);
      expect(find.text('Sheet Content'), findsOneWidget);

      final sheetFinder = find.byType(StandardBottomSheet);
      expect(sheetFinder, findsOneWidget);

      final sheetSize = tester.getSize(sheetFinder);
      final sheetTopLeft = tester.getTopLeft(sheetFinder);

      // Sheet must not stretch to 800px full height
      expect(sheetSize.height, lessThan(400));
      // Sheet must be constrained to maxWidth: 640
      expect(sheetSize.width, lessThanOrEqualTo(640));
      // Sheet must be docked at bottom (top of sheet >= 800 - 400 = 400)
      expect(sheetTopLeft.dy, greaterThan(400));
    });
  });

  group('Theme Selection Tests', () {
    testWidgets('MaterialApp applies Light theme even when system brightness is dark', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(() {
        tester.platformDispatcher.clearPlatformBrightnessTestValue();
      });

      late BuildContext capturedContext;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith((ref) => _TestSettingsNotifier(
              const AppSettings(themeMode: AppThemeMode.light),
            )),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final settings = ref.watch(settingsProvider);
              final seedColor = Color(settings.seedColor);
              final themeMode = switch (settings.themeMode) {
                AppThemeMode.light => ThemeMode.light,
                AppThemeMode.dark => ThemeMode.dark,
                AppThemeMode.system => ThemeMode.system,
              };

              return MaterialApp(
                themeMode: themeMode,
                theme: AppTheme.light(seedColor: seedColor),
                darkTheme: AppTheme.dark(seedColor: seedColor),
                home: Builder(
                  builder: (ctx) {
                    capturedContext = ctx;
                    return const Scaffold(body: Text('Theme Test'));
                  },
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final currentTheme = Theme.of(capturedContext);
      expect(currentTheme.brightness, Brightness.light);
      expect(currentTheme.scaffoldBackgroundColor, AppTheme.lightSurface);
    });

    testWidgets('MaterialApp applies Dark theme even when system brightness is light', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(() {
        tester.platformDispatcher.clearPlatformBrightnessTestValue();
      });

      late BuildContext capturedContext;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith((ref) => _TestSettingsNotifier(
              const AppSettings(themeMode: AppThemeMode.dark),
            )),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final settings = ref.watch(settingsProvider);
              final seedColor = Color(settings.seedColor);
              final themeMode = switch (settings.themeMode) {
                AppThemeMode.light => ThemeMode.light,
                AppThemeMode.dark => ThemeMode.dark,
                AppThemeMode.system => ThemeMode.system,
              };

              return MaterialApp(
                themeMode: themeMode,
                theme: AppTheme.light(seedColor: seedColor),
                darkTheme: AppTheme.dark(seedColor: seedColor),
                home: Builder(
                  builder: (ctx) {
                    capturedContext = ctx;
                    return const Scaffold(body: Text('Theme Test'));
                  },
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final currentTheme = Theme.of(capturedContext);
      expect(currentTheme.brightness, Brightness.dark);
      expect(currentTheme.scaffoldBackgroundColor, AppTheme.darkSurface);
    });

    testWidgets('MaterialApp follows system brightness when in system theme mode', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(() {
        tester.platformDispatcher.clearPlatformBrightnessTestValue();
      });

      late BuildContext capturedContext;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith((ref) => _TestSettingsNotifier(
              const AppSettings(themeMode: AppThemeMode.system),
            )),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final settings = ref.watch(settingsProvider);
              final seedColor = Color(settings.seedColor);
              final themeMode = switch (settings.themeMode) {
                AppThemeMode.light => ThemeMode.light,
                AppThemeMode.dark => ThemeMode.dark,
                AppThemeMode.system => ThemeMode.system,
              };

              return MaterialApp(
                themeMode: themeMode,
                theme: AppTheme.light(seedColor: seedColor),
                darkTheme: AppTheme.dark(seedColor: seedColor),
                home: Builder(
                  builder: (ctx) {
                    capturedContext = ctx;
                    return const Scaffold(body: Text('Theme Test'));
                  },
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(Theme.of(capturedContext).brightness, Brightness.dark);

      // Now toggle system brightness to light
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();

      expect(Theme.of(capturedContext).brightness, Brightness.light);
    });
  });

  group('Floating Bottom Sheet & Standardized UI Design Tests', () {
    testWidgets('StandardBottomSheet renders floating card with 16dp margins and 28dp corner radius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: Scaffold(
            body: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  showSlideBottomSheet<void>(
                    context,
                    builder: (_) => const StandardBottomSheet(
                      title: 'Floating Test',
                      child: Text('Card Content'),
                    ),
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('FLOATING TEST'), findsOneWidget);

      // Check Material widget has borderRadius 28
      final materialFinder = find.descendant(
        of: find.byType(StandardBottomSheet),
        matching: find.byType(Material),
      );
      expect(materialFinder, findsOneWidget);
      final materialWidget = tester.widget<Material>(materialFinder);
      expect(materialWidget.borderRadius, BorderRadius.circular(28));

      // Check outer padding has left 16, right 16, bottom >= 16
      final paddingFinder = find.ancestor(
        of: materialFinder,
        matching: find.byType(Padding),
      ).first;
      final paddingWidget = tester.widget<Padding>(paddingFinder);
      final padding = paddingWidget.padding as EdgeInsets;
      expect(padding.left, 16.0);
      expect(padding.right, 16.0);
      expect(padding.bottom, greaterThanOrEqualTo(16.0));
    });

    testWidgets('ConfirmationBottomSheet renders badge, title, message and returns user action', (tester) async {
      bool? userChoice;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: Scaffold(
            body: Builder(
              builder: (context) => GestureDetector(
                onTap: () async {
                  userChoice = await showConfirmationBottomSheet(
                    context,
                    icon: Icons.delete_forever,
                    title: 'Delete Item?',
                    message: 'This action is irreversible.',
                    confirmLabel: 'Delete',
                    cancelLabel: 'Keep',
                    isDestructive: true,
                  );
                },
                child: const Text('Confirm Action'),
              ),
            ),
          ),
        ),
      );

      // Tap to open sheet
      await tester.tap(find.text('Confirm Action'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Item?'), findsOneWidget);
      expect(find.text('This action is irreversible.'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Keep'), findsOneWidget);

      // Verify Material card in ConfirmationBottomSheet has 28dp radius
      final materialFinder = find.descendant(
        of: find.byType(ConfirmationBottomSheet),
        matching: find.byType(Material),
      );
      final materialWidget = tester.widget<Material>(materialFinder.first);
      expect(materialWidget.borderRadius, BorderRadius.circular(28));

      // Tap confirm button
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(userChoice, isTrue);
      expect(find.text('Delete Item?'), findsNothing);
    });

    testWidgets('showConfirmDeleteDialog delegates to ConfirmationBottomSheet with destructive action', (tester) async {
      bool? deleted;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: Scaffold(
            body: Builder(
              builder: (context) => GestureDetector(
                onTap: () async {
                  deleted = await showConfirmDeleteDialog(
                    context,
                    issuer: 'GitHub',
                    accountLabel: 'user@example.com',
                  );
                },
                child: const Text('Delete OTP'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Delete OTP'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Account'), findsOneWidget);
      expect(find.text('Remove GitHub (user@example.com)? This cannot be undone.'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(deleted, isFalse);
      expect(find.text('Delete Account'), findsNothing);
    });

    testWidgets('showOptionPickerSheet renders options with check indicator and returns selected value', (tester) async {
      String? selectedValue = 'system';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: Scaffold(
            body: Builder(
              builder: (context) => GestureDetector(
                onTap: () async {
                  final result = await showOptionPickerSheet(
                    context,
                    title: 'Theme',
                    options: const [
                      ('Light', 'light'),
                      ('Dark', 'dark'),
                      ('System', 'system'),
                    ],
                    selected: selectedValue!,
                  );
                  if (result != null) selectedValue = result;
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('THEME'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);

      // Select 'Dark'
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(selectedValue, 'dark');
      expect(find.text('THEME'), findsNothing);
    });

    testWidgets('SettingsRow applies 16dp horizontal padding and w600/w400 typography', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: const Scaffold(
            body: SettingsRow(
              leading: Icon(Icons.security),
              title: 'PIN Protection',
              subtitle: 'Secure your vaults',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find SettingsRow padding
      final paddingFinder = find.descendant(
        of: find.byType(SettingsRow),
        matching: find.byType(Padding),
      ).first;
      final paddingWidget = tester.widget<Padding>(paddingFinder);
      final padding = paddingWidget.padding as EdgeInsets;
      expect(padding.left, 16.0);
      expect(padding.right, 16.0);

      // Find title Text
      final titleFinder = find.text('PIN Protection');
      expect(titleFinder, findsOneWidget);
      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.style?.fontWeight, FontWeight.w600);

      // Find subtitle Text
      final subtitleFinder = find.text('Secure your vaults');
      expect(subtitleFinder, findsOneWidget);
      final subtitleWidget = tester.widget<Text>(subtitleFinder);
      expect(subtitleWidget.style?.fontWeight, FontWeight.w400);
    });

    testWidgets('ThinDivider applies 66dp indent and 16dp endIndent', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: const Scaffold(
            body: ThinDivider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final containerFinder = find.descendant(
        of: find.byType(ThinDivider),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsOneWidget);
      final container = tester.widget<Container>(containerFinder);
      final margin = container.margin as EdgeInsets;
      expect(margin.left, 66.0);
      expect(margin.right, 16.0);
    });
  });
}

