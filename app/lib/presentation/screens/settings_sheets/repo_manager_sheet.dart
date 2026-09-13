import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/api/repo_api.dart';
import '../../providers/app_init_provider.dart';
import '../../providers/repo_provider.dart';
import '../../widgets/aosa_input.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/standard_bottom_sheet.dart';

class RepoManagerSheet extends ConsumerStatefulWidget {
  const RepoManagerSheet({super.key});

  @override
  ConsumerState<RepoManagerSheet> createState() => _RepoManagerSheetState();
}

class _RepoManagerSheetState extends ConsumerState<RepoManagerSheet> {
  List<RepoInfo> _repos = [];
  String _activeRepoId = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final services = ref.read(appInitProvider);
    if (services == null) {
      setState(() { _isLoading = false; _error = 'App not initialized'; });
      return;
    }

    try {
      final repos = await RepoApi(services.apiClient.dio).list();
      await ref.read(repoProvider.notifier).loadRepos(services.apiClient);
      final activeId = ref.read(repoProvider).activeRepoId;
      setState(() {
        _repos = repos;
        _activeRepoId = activeId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; _error = 'Failed to load repos'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingTheme = ShadTheme.maybeOf(context);
    final isDark = existingTheme?.brightness == Brightness.dark ||
        Theme.of(context).brightness == Brightness.dark;
    final seed = Theme.of(context).colorScheme.primary;
    final theme = existingTheme ??
        (isDark
            ? AppTheme.shadThemeDark(seedColor: seed)
            : AppTheme.shadThemeLight(seedColor: seed));

    final sheet = StandardBottomSheet(
      title: 'Repos',
      confirmLabel: 'Add',
      onConfirm: _isLoading ? null : _showCreateDialog,
      child: _buildContent(theme),
    );

    if (existingTheme == null) {
      return ShadTheme(
        data: theme,
        child: sheet,
      );
    }
    return sheet;
  }

  Widget _buildContent(ShadThemeData theme) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: AosaLoadingIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(_error!, style: TextStyle(color: theme.colorScheme.destructive)),
        ),
      );
    }

    if (_repos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No repositories')),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _repos.map((repo) {
        final isActive = repo.id == _activeRepoId;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _selectRepo(repo),
            child: ShadCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: isActive
                  ? ShadBorder.all(color: theme.colorScheme.primary, width: 1.5)
                  : null,
              backgroundColor: isActive
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : null,
              child: Row(
                children: [
                  Icon(
                    repo.isDefault ? LucideIcons.star : LucideIcons.folder,
                    size: 18,
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.mutedForeground,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          repo.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w500,
                            color: theme.colorScheme.foreground,
                          ),
                        ),
                        if (repo.isDefault)
                          Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!repo.isDefault)
                    ShadButton.ghost(
                      size: ShadButtonSize.sm,
                      width: 32,
                      height: 32,
                      padding: EdgeInsets.zero,
                      onPressed: () => _deleteRepo(repo),
                      child: Icon(
                        LucideIcons.trash2,
                        size: 16,
                        color: theme.colorScheme.destructive,
                      ),
                    ),
                  if (isActive)
                    Icon(LucideIcons.check, size: 18, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _selectRepo(RepoInfo repo) async {
    if (repo.id == _activeRepoId) return;
    await ref.read(repoProvider.notifier).setActiveRepoId(repo.id);
    setState(() => _activeRepoId = repo.id);
  }

  Future<void> _deleteRepo(RepoInfo repo) async {
    final services = ref.read(appInitProvider);
    if (services == null) return;

    final error = await ref.read(repoProvider.notifier).deleteRepo(
          services.apiClient,
          repo.id,
        );
    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    if (repo.id == _activeRepoId && _repos.length > 1) {
      final remaining = _repos.where((r) => r.id != repo.id).toList();
      final fallback = remaining.firstWhere(
        (r) => r.isDefault,
        orElse: () => remaining.first,
      );
      await ref.read(repoProvider.notifier).setActiveRepoId(fallback.id);
      setState(() {
        _repos.removeWhere((r) => r.id == repo.id);
        _activeRepoId = fallback.id;
      });
    } else {
      setState(() => _repos.removeWhere((r) => r.id == repo.id));
    }
  }

  void _showCreateDialog() {
    showSlideBottomSheet<void>(
      context,
      isScrollControlled: true,
      builder: (_) => _CreateRepoSheet(
        onCreate: (name) async {
          final services = ref.read(appInitProvider);
          if (services == null) return 'App not initialized';

          final error = await ref.read(repoProvider.notifier).createRepo(
                services.apiClient,
                name,
              );
          if (error == null) {
            await _load();
          }
          return error;
        },
      ),
    );
  }
}

class _CreateRepoSheet extends StatefulWidget {
  final Future<String?> Function(String name) onCreate;

  const _CreateRepoSheet({required this.onCreate});

  @override
  State<_CreateRepoSheet> createState() => _CreateRepoSheetState();
}

class _CreateRepoSheetState extends State<_CreateRepoSheet> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final error = await widget.onCreate(name);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StandardBottomSheet(
      title: 'Create Repo',
      confirmLabel: _submitting ? 'Creating...' : 'Create',
      onConfirm: _submitting ? null : _submit,
      onBack: () => Navigator.of(context).pop(),
      isScrollControlled: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: AosaInput(
          controller: _controller,
          label: 'Repository name',
          hint: 'e.g. Personal Vault, Work',
          leadingIcon: LucideIcons.folder,
          autofocus: true,
          onSubmitted: (_) => _submit(),
        ),
      ),
    );
  }
}
