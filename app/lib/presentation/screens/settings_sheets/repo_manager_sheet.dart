import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api/repo_api.dart';
import '../../providers/app_init_provider.dart';
import '../../providers/repo_provider.dart';
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
    final cs = Theme.of(context).colorScheme;

    return StandardBottomSheet(
      title: 'Repos',
      confirmLabel: 'Add',
      onConfirm: _isLoading ? null : _showCreateDialog,
      child: _buildContent(cs),
    );
  }

  Widget _buildContent(ColorScheme cs) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(_error!, style: TextStyle(color: cs.error)),
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
        return ListTile(
          dense: true,
          leading: Icon(
            repo.isDefault ? Icons.star : Icons.folder_outlined,
            color: isActive ? cs.primary : cs.onSurfaceVariant,
          ),
          title: Text(repo.name),
          subtitle: repo.isDefault
              ? Text('Default',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!repo.isDefault)
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                  onPressed: () => _deleteRepo(repo),
                ),
              if (isActive)
                Icon(Icons.check_circle, size: 18, color: cs.primary)
              else
                Icon(Icons.circle_outlined, size: 18, color: cs.outline),
            ],
          ),
          onTap: () => _selectRepo(repo),
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
        child: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Repo name',
            hintText: 'My Vault',
          ),
          autofocus: true,
          onSubmitted: (_) => _submit(),
        ),
      ),
    );
  }
}
