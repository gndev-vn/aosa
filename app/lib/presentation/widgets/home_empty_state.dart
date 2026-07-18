import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeEmptyState extends StatelessWidget {
  final String? searchQuery;

  const HomeEmptyState({super.key, this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasFilter = searchQuery != null && searchQuery!.isNotEmpty;

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
                'No results for "$searchQuery"',
                style: theme.textTheme.titleMedium,
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
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(delay: 200.ms, duration: 400.ms, curve: Curves.elasticOut),
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
}
