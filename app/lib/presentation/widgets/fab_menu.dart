import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';

class FabMenuAction {
  final IconData icon;
  final String? label;
  final Color? color;
  final Color? iconColor;
  final bool isPrimary;
  final VoidCallback onTap;

  const FabMenuAction({
    required this.icon,
    this.label,
    this.color,
    this.iconColor,
    this.isPrimary = false,
    required this.onTap,
  });
}

OverlayEntry? _activeOverlay;

void dismissFabMenu() {
  _activeOverlay?.remove();
  _activeOverlay = null;
}

void showFabMenu(BuildContext context, {required List<FabMenuAction> actions}) {
  dismissFabMenu();

  final overlay = Overlay.of(context);
  final entry = OverlayEntry(builder: (_) => _FabMenuOverlay(actions: actions));

  _activeOverlay = entry;
  overlay.insert(entry);
}

class _FabMenuOverlay extends StatefulWidget {
  final List<FabMenuAction> actions;
  const _FabMenuOverlay({required this.actions});

  @override
  State<_FabMenuOverlay> createState() => _FabMenuOverlayState();
}

class _FabMenuOverlayState extends State<_FabMenuOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final List<Animation<double>> _itemAnims;
  bool _dismissing = false;

  static const _fabSize = 56.0;
  static const _fabMargin = 16.0;
  static const _itemSize = 44.0;
  static const _itemSpacing = 14.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _itemAnims = List.generate(widget.actions.length, (i) {
      final start = i * 0.08;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeOutBack),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _close() {
    if (_dismissing) return;
    _dismissing = true;
    _ctrl.reverse().then((_) {
      if (mounted) dismissFabMenu();
    });
  }

  Offset _fabCenter(Size screen, EdgeInsets padding) {
    return Offset(
      screen.width - _fabMargin - _fabSize / 2,
      screen.height - padding.bottom - _fabMargin - _fabSize / 2,
    );
  }

  Offset _itemCenter(int index, int total, Size screen, EdgeInsets padding) {
    final fab = _fabCenter(screen, padding);
    final reversedIndex = total - 1 - index;
    return Offset(
      fab.dx,
      fab.dy - _fabSize / 2 - _itemSpacing - reversedIndex * (_itemSize + _itemSpacing) - _itemSize / 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final existingTheme = ShadTheme.maybeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final seedColor = Theme.of(context).colorScheme.primary;
    final shadTheme = existingTheme ??
        (isDark
            ? AppTheme.shadThemeDark(seedColor: seedColor)
            : AppTheme.shadThemeLight(seedColor: seedColor));
    final total = widget.actions.length;

    final content = AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Dim background
              GestureDetector(
                onTap: _close,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.black.withValues(alpha: 0.3 * _fadeIn.value)),
              ),

              // Action buttons
              for (int i = 0; i < total; i++)
                _buildItem(widget.actions[i], i, total, size, padding, shadTheme),

              // FAB
              Positioned(
                right: _fabMargin,
                bottom: padding.bottom + _fabMargin,
                child: ShadButton(
                  width: _fabSize,
                  height: _fabSize,
                  padding: EdgeInsets.zero,
                  decoration: const ShadDecoration(shape: BoxShape.circle),
                  onPressed: _close,
                  child: AnimatedRotation(
                    turns: _fadeIn.value * 0.125, // 45 degrees
                    duration: Duration.zero,
                    child: const Icon(LucideIcons.plus, size: 24),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (existingTheme == null) {
      return ShadTheme(
        data: shadTheme,
        child: content,
      );
    }
    return content;
  }

  Widget _buildItem(
    FabMenuAction action,
    int index,
    int total,
    Size screen,
    EdgeInsets padding,
    ShadThemeData shadTheme,
  ) {
    final d = _itemAnims[index].value;
    if (d <= 0) return const SizedBox.shrink();

    final target = _itemCenter(index, total, screen, padding);
    final fab = _fabCenter(screen, padding);
    final pos = Offset.lerp(fab, target, d)!;

    final Widget actionButton;
    if (action.isPrimary || action.color != null) {
      actionButton = ShadButton(
        width: _itemSize,
        height: _itemSize,
        padding: EdgeInsets.zero,
        backgroundColor: action.color ?? shadTheme.colorScheme.primary,
        foregroundColor: action.iconColor ?? shadTheme.colorScheme.primaryForeground,
        decoration: const ShadDecoration(shape: BoxShape.circle),
        onPressed: () {
          HapticFeedback.lightImpact();
          _close();
          Future.delayed(const Duration(milliseconds: 200), action.onTap);
        },
        child: Icon(action.icon, size: 18),
      );
    } else {
      actionButton = ShadButton.outline(
        width: _itemSize,
        height: _itemSize,
        padding: EdgeInsets.zero,
        decoration: const ShadDecoration(shape: BoxShape.circle),
        onPressed: () {
          HapticFeedback.lightImpact();
          _close();
          Future.delayed(const Duration(milliseconds: 200), action.onTap);
        },
        child: Icon(
          action.icon,
          size: 18,
          color: action.iconColor ?? shadTheme.colorScheme.foreground,
        ),
      );
    }

    return Positioned(
      right: _fabMargin + (_fabSize - _itemSize) / 2,
      top: pos.dy - _itemSize / 2,
      child: FadeTransition(
        opacity: _itemAnims[index],
        child: ScaleTransition(
          scale: _itemAnims[index],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (action.label != null) ...[
                ShadCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    action.label!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: shadTheme.colorScheme.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              actionButton,
            ],
          ),
        ),
      ),
    );
  }
}
