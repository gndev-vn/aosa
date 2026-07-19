import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api/repo_api.dart';
import '../../providers/app_init_provider.dart';
import '../../providers/repo_provider.dart';
import '../../widgets/standard_bottom_sheet.dart';

class RepoManagerSheet extends ConsumerStatefulWidget {
  final List<RepoInfo> repos;

  const RepoManagerSheet({super.key, required this.repos});

  @override
  ConsumerState<RepoManagerSheet> createState() => _RepoManagerSheetState();
}

class _RepoManagerSheetState extends ConsumerState<RepoManagerSheet> {
  late List<RepoInfo> _repos;

  @override
  void initState() {
    super.initState();
    _repos = List.from(widget.repos);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return StandardBottomSheet(
      title: 'Repos',
      confirmLabel: 'Add',
      onConfirm: () => _showCreateDialog(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._repos.map((repo) => ListTile(
                dense: true,
                leading: Icon(
                  repo.isDefault ? Icons.star : Icons.folder_outlined,
                  color: cs.primary,
                ),
                title: Text(repo.name),
                subtitle: repo.isDefault
                    ? Text('Default',
                        style:
                            TextStyle(fontSize: 12, color: cs.onSurfaceVariant))
                    : null,
                trailing: !repo.isDefault
                    ? IconButton(
                        icon:
                            Icon(Icons.delete_outline, size: 18, color: cs.error),
                        onPressed: () => _deleteRepo(repo),
                      )
                    : null,
              )),
        ],
      ),
    );
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
    setState(() {
      _repos.removeWhere((r) => r.id == repo.id);
    });
  }

  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Repo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Repo name',
            hintText: 'My Vault',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              final services = ref.read(appInitProvider);
              if (services == null) return;

              final error = await ref.read(repoProvider.notifier).createRepo(
                    services.apiClient,
                    name,
                  );
              if (error != null) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
                  );
                }
                return;
              }

              if (ctx.mounted) Navigator.of(ctx).pop();
              final repos = ref.read(repoProvider).valueOrNull ?? [];
              setState(() => _repos = List.from(repos));
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
