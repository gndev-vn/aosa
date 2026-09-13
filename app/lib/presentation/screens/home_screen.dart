
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/theme/app_theme.dart';
import '../providers/app_init_provider.dart';
import '../providers/app_lock_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/otp_list_provider.dart';
import '../providers/repo_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/sync_provider.dart';
import '../widgets/add_otp_bottom_sheet.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/fab_menu.dart';
import '../widgets/home_empty_state.dart';
import '../widgets/home_header.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/otp_card.dart';
import '../widgets/repo_picker_sheet.dart';
import '../widgets/standard_bottom_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  OtpListNotifier? _otpNotifier;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  String? _activeRepoId;
  bool _shownConnectionError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );
    _fabController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpNotifier = ref.read(otpListProvider.notifier);
      _otpNotifier?.startAutoRefresh();
      _loadActiveRepoId();
    });
  }


  Future<void> _loadActiveRepoId() async {
    final services = ref.read(appInitProvider);
    if (services != null) {
      ref.read(repoProvider.notifier).setDatabase(services.database);
    }
    final id = ref.read(repoProvider).activeRepoId;
    if (id.isEmpty) {
      if (services != null && services.apiClient.hasBaseUrl) {
        await ref.read(repoProvider.notifier).loadRepos(services.apiClient);
        final updated = ref.read(repoProvider).activeRepoId;
        if (mounted) setState(() => _activeRepoId = updated.isEmpty ? null : updated);
      }
    } else {
      if (mounted) setState(() => _activeRepoId = id);
    }
  }

  void _showFabMenu(BuildContext context, WidgetRef ref) {
    final repo = ref.read(otpRepositoryProvider);
    if (repo == null) return;

    showFabMenu(context, actions: [
      FabMenuAction(
        icon: LucideIcons.scanLine,
        label: 'Scan QR code',
        isPrimary: true,
        onTap: () => showAddOtpSheet(context, ref, repo, startMode: AddOtpMode.scan),
      ),
      FabMenuAction(
        icon: LucideIcons.link,
        label: 'Paste URI',
        onTap: () => showAddOtpSheet(context, ref, repo, startMode: AddOtpMode.uri),
      ),
      FabMenuAction(
        icon: LucideIcons.pencil,
        label: 'Manual entry',
        onTap: () => showAddOtpSheet(context, ref, repo),
      ),
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _otpNotifier?.stopAutoRefresh();
    _searchController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(otpListProvider.notifier);
    if (state == AppLifecycleState.resumed) {
      notifier.startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      notifier.stopAutoRefresh();
      if (ref.read(appLockProvider).pinEnabled) ref.read(appLockProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(otpListProvider);
    final settings = ref.watch(settingsProvider);
    final authFlow = ref.watch(authProvider);
    final query = _searchQuery.toLowerCase();
    final filtered = query.isEmpty
        ? items
        : items.where((e) => e.account.issuer.toLowerCase().contains(query) || e.account.accountLabel.toLowerCase().contains(query)).toList();

    if (settings.syncEnabled && authFlow == AuthFlow.unauthenticated && !_shownConnectionError) {
      _shownConnectionError = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection to server failed. Sync data will remain persistent.'), behavior: SnackBarBehavior.floating),
        );
      });
    } else if (authFlow == AuthFlow.authenticated) {
      _shownConnectionError = false;
    }

    final existingTheme = ShadTheme.maybeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final seed = Theme.of(context).colorScheme.primary;
    final shadTheme = existingTheme ??
        (isDark
            ? AppTheme.shadThemeDark(seedColor: seed)
            : AppTheme.shadThemeLight(seedColor: seed));

    final scaffold = Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(children: [
              _buildHeader(),
              HomeSearchBar(
                controller: _searchController,
                searchQuery: _searchQuery,
                onChanged: (v) => setState(() => _searchQuery = v),
                onClear: () { _searchController.clear(); setState(() => _searchQuery = ''); },
              ),
              Expanded(
                child: filtered.isEmpty
                    ? HomeEmptyState(
                        searchQuery:
                            _searchQuery.isNotEmpty ? _searchQuery : null,
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 600;
                          final list = isWide
                              ? GridView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    mainAxisExtent: 110,
                                  ),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) => OtpCard(
                                    key: ValueKey(filtered[index].account.id),
                                    item: filtered[index],
                                    compact: true,
                                    onEdit: () => _showOtpActions(
                                      context,
                                      ref,
                                      filtered[index],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) => OtpCard(
                                    key: ValueKey(filtered[index].account.id),
                                    item: filtered[index],
                                    onEdit: () => _showOtpActions(
                                      context,
                                      ref,
                                      filtered[index],
                                    ),
                                  ),
                                );

                          return RefreshIndicator(
                            onRefresh: () async {
                              await HapticFeedback.mediumImpact();
                              await Future<void>.delayed(
                                const Duration(milliseconds: 500),
                              );
                            },
                            child: list,
                          );
                        },
                      ),
              ),
            ]),
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: ShadButton(
          width: 56,
          height: 56,
          padding: EdgeInsets.zero,
          decoration: const ShadDecoration(
            shape: BoxShape.circle,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            _showFabMenu(context, ref);
          },
          child: const Icon(LucideIcons.plus, size: 24),
        ),
      ),
    );

    if (existingTheme == null) {
      return ShadTheme(
        data: shadTheme,
        child: scaffold,
      );
    }
    return scaffold;
  }

  Widget _buildHeader() {
    final settings = ref.watch(settingsProvider);
    final reposState = ref.watch(repoProvider);
    final syncState = ref.watch(syncProvider);
    final authFlow = ref.watch(authProvider);
    final activeName = _activeRepoId != null
        ? reposState.repos.where((r) => r.id == _activeRepoId).firstOrNull?.name
        : null;

    return HomeHeader(
      syncEnabled: settings.syncEnabled,
      isAuthenticated: authFlow == AuthFlow.authenticated,
      syncState: syncState,
      activeRepoName: activeName,
      onSync: () => _triggerSync(context),
      onSelectRepo: _showRepoPicker,
      onSettings: () => ref.read(navigationProvider.notifier).goToSettings(),
    );
  }

  void _showRepoPicker() {
    final repos = ref.read(repoProvider).repos;
    if (repos.isEmpty) return;
    showSlideBottomSheet<String>(
      context,
      builder: (ctx) => RepoPickerSheet(repos: repos, currentRepoId: _activeRepoId),
    ).then((selected) {
      if (selected != null && selected != _activeRepoId) {
        ref.read(repoProvider.notifier).setActiveRepoId(selected);
        if (mounted) setState(() => _activeRepoId = selected);
      }
    });
  }

  Future<void> _triggerSync(BuildContext context) async {
    final error = await ref.read(syncProvider.notifier).runSync(ref);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _showOtpActions(BuildContext context, WidgetRef ref, OtpCodeWithAccount item) {
    final nav = ref.read(navigationProvider.notifier);
    final repo = ref.read(otpRepositoryProvider);
    final cs = Theme.of(context).colorScheme;
    final formattedCode = item.code.code.length == 6
        ? '${item.code.code.substring(0, 3)} ${item.code.code.substring(3)}'
        : item.code.code;

    final shadTheme = ShadTheme.maybeOf(context);
    final fgColor = shadTheme?.colorScheme.foreground ?? cs.onSurface;

    showSlideBottomSheet<void>(
      context,
      builder: (sheetContext) => StandardBottomSheet(
        title: item.account.issuer,
        child: Column(children: [
          ShadCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Center(
              child: Text(
                formattedCode,
                style: AppTheme.codeStyle(
                  color: fgColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _actionTile(
            icon: LucideIcons.copy,
            title: 'Copy code',
            onTap: () {
              Navigator.of(sheetContext).pop();
              Clipboard.setData(ClipboardData(text: item.code.code));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          _actionTile(
            icon: LucideIcons.pencil,
            title: 'Edit account',
            onTap: () {
              Navigator.of(sheetContext).pop();
              nav.goToEditOtp(item.account.id);
            },
          ),
          _actionTile(
            icon: LucideIcons.trash2,
            title: 'Delete account',
            isDestructive: true,
            onTap: () async {
              Navigator.of(sheetContext).pop();
              if (await showConfirmDeleteDialog(context, issuer: item.account.issuer, accountLabel: null)) {
                await repo?.delete(item.account.id);
                await HapticFeedback.mediumImpact();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.account.issuer} deleted'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
        ]),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Builder(builder: (context) {
      final existingTheme = ShadTheme.maybeOf(context);
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final seed = Theme.of(context).colorScheme.primary;
      final shadTheme = existingTheme ??
          (isDark
              ? AppTheme.shadThemeDark(seedColor: seed)
              : AppTheme.shadThemeLight(seedColor: seed));
      final muted = shadTheme.colorScheme.mutedForeground;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: isDestructive
            ? ShadButton.destructive(
                width: double.infinity,
                height: 48,
                mainAxisAlignment: MainAxisAlignment.start,
                onPressed: onTap,
                leading: Icon(icon, size: 18),
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              )
            : ShadButton.outline(
                width: double.infinity,
                height: 48,
                mainAxisAlignment: MainAxisAlignment.start,
                onPressed: onTap,
                leading: Icon(
                  icon,
                  size: 18,
                  color: muted,
                ),
                trailing: Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: muted,
                ),
                child: Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: shadTheme.colorScheme.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
      );
    });
  }
}
