import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FabMenuAction {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const FabMenuAction({
    required this.icon,
    required this.color,
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
      final start = i * 0.12;
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
    final cs = Theme.of(context).colorScheme;
    final total = widget.actions.length;

    return AnimatedBuilder(
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
                _buildItem(widget.actions[i], i, total, size, padding, cs),

              // FAB
              Positioned(
                right: _fabMargin,
                bottom: padding.bottom + _fabMargin,
                child: GestureDetector(
                  onTap: _close,
                  child: Container(
                    width: _fabSize,
                    height: _fabSize,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: AnimatedRotation(
                      turns: _fadeIn.value * 0.125, // 45 degrees
                      duration: Duration.zero,
                      child: Icon(Icons.add, color: cs.onPrimary, size: 28),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItem(
    FabMenuAction action,
    int index,
    int total,
    Size screen,
    EdgeInsets padding,
    ColorScheme cs,
  ) {
    final d = _itemAnims[index].value;
    if (d <= 0) return const SizedBox.shrink();

    final target = _itemCenter(index, total, screen, padding);
    final fab = _fabCenter(screen, padding);
    final pos = Offset.lerp(fab, target, d)!;

    return Positioned(
      left: pos.dx - _itemSize / 2,
      top: pos.dy - _itemSize / 2,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _close();
          Future.delayed(const Duration(milliseconds: 200), action.onTap);
        },
        child: ScaleTransition(
          scale: _itemAnims[index],
          child: Container(
            width: _itemSize,
            height: _itemSize,
            decoration: BoxDecoration(
              color: action.color,
              shape: BoxShape.circle,
            ),
            child: Icon(action.icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
