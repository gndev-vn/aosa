import 'package:flutter/material.dart';

import '../../data/api/repo_api.dart';
import 'standard_bottom_sheet.dart';

class RepoPickerSheet extends StatelessWidget {
  final List<RepoInfo> repos;
  final String? currentRepoId;

  const RepoPickerSheet({super.key, required this.repos, this.currentRepoId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return StandardBottomSheet(
      title: 'Select Repo',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...repos.map((repo) => ListTile(
                leading: Icon(
                  repo.isDefault ? Icons.star : Icons.folder_outlined,
                  color: cs.primary,
                ),
                title: Text(repo.name),
                subtitle: repo.shared
                    ? Text('Shared',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant))
                    : null,
                trailing: repo.id == currentRepoId
                    ? Icon(Icons.check, size: 18, color: cs.primary)
                    : Icon(Icons.chevron_right,
                        size: 18, color: cs.onSurfaceVariant),
                onTap: () => Navigator.of(context).pop(repo.id),
              )),
          if (repos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No repos found',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ),
            ),
        ],
      ),
    );
  }
}
