import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  OtpListNotifier? _otpNotifier;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;
  String? _activeRepoId;
  bool _shownConnectionError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fabController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fabAnimation = CurvedAnimation(parent: _fabController, curve: Curves.elasticOut);
    _fabController.forward();

    // Breathing idle animation for the FAB
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _breathAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
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
    final cs = Theme.of(context).colorScheme;

    showFabMenu(context, actions: [
      FabMenuAction(
        icon: Icons.qr_code_scanner_rounded,
        color: cs.primary,
        onTap: () => showAddOtpSheet(context, ref, repo, startMode: AddOtpMode.scan),
      ),
      FabMenuAction(
        icon: Icons.link_rounded,
        color: cs.secondary,
        onTap: () => showAddOtpSheet(context, ref, repo, startMode: AddOtpMode.uri),
      ),
      FabMenuAction(
        icon: Icons.edit_outlined,
        color: cs.tertiary,
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
    _breathController.dispose();
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
    final cs = Theme.of(context).colorScheme;
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

    return Scaffold(
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
                    ? HomeEmptyState(searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null)
                    : RefreshIndicator(
                        onRefresh: () async { await HapticFeedback.mediumImpact(); await Future<void>.delayed(const Duration(milliseconds: 500)); },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => OtpCard(
                            key: ValueKey(filtered[index].account.id),
                            item: filtered[index],
                            onEdit: () => _showOtpActions(context, ref, filtered[index]),
                          ),
                        ),
                      ),
              ),
            ]),
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: AnimatedBuilder(
          animation: _breathAnimation,
          builder: (context, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(
                1.0 / math.sqrt(_breathAnimation.value),
                _breathAnimation.value,
                1.0,
              ),
              child: child,
            );
          },
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showFabMenu(context, ref);
            },
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cs.primary, cs.primary.withAlpha(200)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: cs.primary.withAlpha(60), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Icon(Icons.add, color: cs.onPrimary),
            ),
          ),
        ),
      ),
    );
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

    showSlideBottomSheet<void>(
      context,
      builder: (_) => StandardBottomSheet(
        title: item.account.issuer,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: cs.primaryContainer.withAlpha(80), borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text(item.code.code, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 3, fontFamily: 'monospace', color: cs.onPrimaryContainer))),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          _actionTile(cs, Icons.copy_rounded, 'Copy code', cs.primaryContainer, cs.onPrimaryContainer, () {
            Navigator.of(context).pop();
            Clipboard.setData(ClipboardData(text: item.code.code));
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Copied to clipboard'), duration: const Duration(seconds: 2), action: SnackBarAction(label: 'OK', onPressed: () {})));
          }),
          _actionTile(cs, Icons.edit_outlined, 'Edit account', cs.secondaryContainer, cs.onSecondaryContainer, () {
            Navigator.of(context).pop();
            nav.goToEditOtp(item.account.id);
          }),
          _actionTile(cs, Icons.delete_outline_rounded, 'Delete account', cs.errorContainer, cs.onErrorContainer, () async {
            Navigator.of(context).pop();
            if (await showConfirmDeleteDialog(context, issuer: item.account.issuer, accountLabel: null)) {
              await repo?.delete(item.account.id);
              await HapticFeedback.mediumImpact();
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.account.issuer} deleted'), duration: const Duration(seconds: 2)));
            }
          }, titleColor: cs.error),
        ]),
      ),
    );
  }

  Widget _actionTile(ColorScheme cs, IconData icon, String title, Color bgColor, Color iconColor, VoidCallback onTap, {Color? titleColor}) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(title, style: titleColor != null ? TextStyle(color: titleColor) : null),
      onTap: onTap,
    );
  }
}
