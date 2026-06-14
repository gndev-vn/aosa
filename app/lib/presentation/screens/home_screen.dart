import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/repositories/otp_repository_impl.dart';
import '../providers/app_lock_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/otp_list_provider.dart';
import '../widgets/add_otp_bottom_sheet.dart';
import '../widgets/aosa_widgets.dart';
import '../widgets/otp_card.dart';

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
      _otpNotifier!.startAutoRefresh();
    });
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
    final lock = ref.read(appLockProvider.notifier);
    if (state == AppLifecycleState.resumed) {
      notifier.startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      notifier.stopAutoRefresh();
      if (ref.read(appLockProvider).pinEnabled) {
        lock.lock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(otpListProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final repo = ref.read(otpRepositoryProvider);
    final filtered = _searchQuery.isEmpty
        ? items
        : items
            .where((e) =>
                e.account.issuer
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                e.account.accountLabel
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, colorScheme),
            _buildSearchBar(theme, colorScheme),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState(
                      theme, colorScheme, _searchQuery.isNotEmpty)
                  : RefreshIndicator(
                      onRefresh: () async {
                        HapticFeedback.mediumImpact();
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return OtpCard(
                            item: filtered[index],
                            onEdit: () =>
                                _showOtpActions(context, ref, filtered[index]),
                          ).animate().fadeIn(
                                duration: 200.ms,
                                delay: (index * 30).ms,
                              );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: SizedBox(
          width: 56,
          height: 56,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              showAddOtpSheet(context, ref, repo);
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withAlpha(200),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withAlpha(60),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(Icons.add, color: colorScheme.onPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
      child: Row(
        children: [
          const SizedBox(width: 40),
          Expanded(
            child: Center(
              child: Text(
                'AOSA',
                style: GoogleFonts.poppins(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          aosaIconButton(
            icon: Icons.settings,
            color: colorScheme.onSurface,
            onPressed: () =>
                ref.read(navigationProvider.notifier).goToSettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Icon(
              Icons.search_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant.withAlpha(150),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Theme(
                data: theme.copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search accounts...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear, size: 14),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      ThemeData theme, ColorScheme colorScheme, bool hasFilter) {
    if (hasFilter) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 72,
                color: colorScheme.onSurfaceVariant.withAlpha(100),
              ),
              const SizedBox(height: 16),
              Text(
                'No results for "$_searchQuery"',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Text('Clear search'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withAlpha(60),
                    colorScheme.primaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: colorScheme.primary,
              ),
            ).animate().fadeIn(duration: 400.ms).scale(
                delay: 200.ms, duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              'No OTP accounts yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
            const SizedBox(height: 10),
            Text(
              'Add your first account to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
          ],
        ),
      ),
    );
  }

  void _showOtpActions(
      BuildContext context, WidgetRef ref, OtpCodeWithAccount item) {
    final nav = ref.read(navigationProvider.notifier);
    final repo = ref.read(otpRepositoryProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withAlpha(180),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          item.account.issuer[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.account.issuer,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            item.account.accountLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.code.code,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          fontFamily: 'monospace',
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                title: const Text('Copy code'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Clipboard.setData(ClipboardData(text: item.code.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Copied to clipboard'),
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'OK',
                        onPressed: () {},
                      ),
                    ),
                  );
                  HapticFeedback.lightImpact();
                },
              ),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                title: const Text('Edit account'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  nav.goToEditOtp(item.account.id);
                },
              ),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
                title: Text('Delete account',
                    style: TextStyle(color: colorScheme.error)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDelete(context, item, repo);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, OtpCodeWithAccount item,
      OtpRepositoryImpl repo) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: cs.surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.delete_outline_rounded,
                    size: 28, color: cs.onErrorContainer),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete Account',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Remove ${item.account.issuer}?',
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(false),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Center(
                          child: Text('Cancel',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(true),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: cs.error,
                        ),
                        child: Center(
                          child: Text('Delete',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onError)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) {
      await repo.delete(item.account.id);
      HapticFeedback.mediumImpact();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.account.issuer} deleted'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
