import 'dart:math' as math;

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
  late final Animation<double> _curve;
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
      duration: const Duration(milliseconds: 500),
    );
    _curve = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _close() {
    if (_dismissing) return;
    _dismissing = true;
    _ctrl.reverse().then((_) => dismissFabMenu());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final cs = Theme.of(context).colorScheme;

    final fabRight = _fabMargin + _fabSize / 2;
    final fabBottom = padding.bottom + _fabMargin + _fabSize / 2;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _curve.value;
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              GestureDetector(
                onTap: _close,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.black.withValues(alpha: 0.3 * t)),
              ),
              for (int i = 0; i < widget.actions.length; i++)
                _buildItem(
                  widget.actions[i],
                  i,
                  t,
                  size,
                  padding,
                  fabRight,
                  fabBottom,
                ),
              Positioned(
                right: _fabMargin,
                bottom: padding.bottom + _fabMargin,
                child: Transform(
                  transform: Matrix4.identity()..rotateZ(t * math.pi / 4),
                  alignment: Alignment.center,
                  child: _buildFab(cs),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFab(ColorScheme cs) {
    return GestureDetector(
      onTap: _close,
      child: Container(
        width: _fabSize,
        height: _fabSize,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.primary.withAlpha(200)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(Icons.add, color: cs.onPrimary, size: 28),
      ),
    );
  }

  Widget _buildItem(
    FabMenuAction action,
    int index,
    double t,
    Size size,
    EdgeInsets padding,
    double fabRight,
    double fabBottom,
  ) {
    final total = widget.actions.length;
    final reversedIndex = total - 1 - index;

    final targetBottom =
        fabBottom + _fabSize / 2 + _itemSpacing + reversedIndex * (_itemSize + _itemSpacing);

    final delay = index * 0.12;
    final itemT = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);

    final springT = Curves.easeOutBack.transform(itemT);
    final itemBottom = fabBottom + (targetBottom - fabBottom) * springT;

    final scaleX = 0.3 + 0.7 * springT;
    final scaleY = 0.3 + 0.7 * springT;

    final stretchY = itemT < 0.4
        ? 1.0 + 0.25 * (1.0 - itemT / 0.4) * math.sin(itemT * math.pi)
        : 1.0;
    final stretchX = itemT < 0.4
        ? 1.0 - 0.12 * (1.0 - itemT / 0.4) * math.sin(itemT * math.pi)
        : 1.0;

    final opacity = itemT > 0.15 ? ((itemT - 0.15) / 0.6).clamp(0.0, 1.0) : 0.0;

    final wobble = itemT < 0.5
        ? math.sin(itemT * math.pi * 2) * 3.0 * (1.0 - itemT * 2)
        : 0.0;

    return Positioned(
      right: _fabMargin + _fabSize / 2 - _itemSize / 2 + wobble,
      bottom: itemBottom,
      child: Opacity(
        opacity: opacity,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _close();
            Future.delayed(const Duration(milliseconds: 200), action.onTap);
          },
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(
              scaleX * stretchX,
              scaleY * stretchY,
              1.0,
            ),
            child: Container(
              width: _itemSize,
              height: _itemSize,
              decoration: BoxDecoration(
                color: action.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: action.color.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(action.icon, size: 20, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
