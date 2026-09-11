import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../presentation/providers/otp_list_provider.dart';
import '../../presentation/providers/totp_ticker_provider.dart';

class OtpCard extends StatefulWidget {
  final OtpCodeWithAccount item;
  final bool compact;
  final VoidCallback? onEdit;

  const OtpCard({
    super.key,
    required this.item,
    this.compact = false,
    this.onEdit,
  });

  @override
  State<OtpCard> createState() => _OtpCardState();
}

class _OtpCardState extends State<OtpCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;
  bool _copied = false;
  Timer? _copiedTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.item.code.code));
    HapticFeedback.lightImpact();

    _copiedTimer?.cancel();
    if (mounted) {
      setState(() => _copied = true);
      _copiedTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _copied = false);
      });
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.compact) {
      return _buildCompactCard(context, colorScheme);
    }
    return _buildFullCard(context, colorScheme);
  }

  Widget _buildFullCard(BuildContext context, ColorScheme colorScheme) {
    final account = widget.item.account;
    final code = widget.item.code;
    final isDark = colorScheme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Transform.scale(
        scale: _isPressed ? _pulseAnimation.value : 1.0,
        child: child,
      ),
      child: GestureDetector(
        onTap: () {
          _pulseController.reverse();
          _copyCode(context);
        },
        onLongPress: widget.onEdit,
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _pulseController.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _pulseController.reverse();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _pulseController.reverse();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardSurface : AppTheme.lightCardSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color: _copied
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withAlpha(50),
              width: _copied ? 1.5 : 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildAvatar(colorScheme, account.issuer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  account.issuer,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_copied) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check, size: 12, color: colorScheme.onPrimaryContainer),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Copied',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            account.accountLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (account.shortcutKey != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            account.shortcutKey!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    _OtpCountdownBadge(
                      period: account.period,
                      fallbackTimeLeft: code.timeLeft,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _formatCode(code.code),
                  style: AppTheme.codeStyle(color: colorScheme.onSurface),
                ),
                const SizedBox(height: 12),
                _OtpProgressBar(
                  period: account.period,
                  fallbackTimeLeft: code.timeLeft,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context, ColorScheme colorScheme) {
    final account = widget.item.account;
    final code = widget.item.code;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardSurface : AppTheme.lightCardSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: ListTile(
        onTap: () => _copyCode(context),
        onLongPress: widget.onEdit,
        leading: _buildAvatar(colorScheme, account.issuer),
        title: Text(
          account.issuer,
          style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        ),
        subtitle: Text(
          _formatCode(code.code),
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
            letterSpacing: 1.5,
          ),
        ),
        trailing: _OtpCountdownBadge(
          period: account.period,
          fallbackTimeLeft: code.timeLeft,
          isCompact: true,
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme, String issuer) {
    final char = issuer.isNotEmpty ? issuer[0].toUpperCase() : '?';
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withAlpha(180),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  String _formatCode(String code) {
    if (code.length <= 3) return code;
    return '${code.substring(0, 3)} ${code.substring(3)}';
  }
}

class _OtpCountdownBadge extends ConsumerWidget {
  final int period;
  final int fallbackTimeLeft;
  final bool isCompact;

  const _OtpCountdownBadge({
    required this.period,
    required this.fallbackTimeLeft,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickerAsync = ref.watch(totpTickerProvider);
    final currentSecond = tickerAsync.valueOrNull ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final timeLeft = calculateTimeLeft(period, currentSecond);
    final progress = calculateProgressFraction(period, currentSecond);
    final isUrgent = timeLeft <= 5;
    final colorScheme = Theme.of(context).colorScheme;

    if (isCompact) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 2.5,
          color: isUrgent ? colorScheme.error : colorScheme.primary,
          backgroundColor: colorScheme.surfaceContainerHighest,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent
            ? colorScheme.error.withAlpha(30)
            : colorScheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${timeLeft}s',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isUrgent ? colorScheme.error : colorScheme.primary,
        ),
      ),
    );
  }
}

class _OtpProgressBar extends ConsumerWidget {
  final int period;
  final int fallbackTimeLeft;

  const _OtpProgressBar({
    required this.period,
    required this.fallbackTimeLeft,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickerAsync = ref.watch(totpTickerProvider);
    final currentSecond = tickerAsync.valueOrNull ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final timeLeft = calculateTimeLeft(period, currentSecond);
    final progress = calculateProgressFraction(period, currentSecond);
    final isUrgent = timeLeft <= 5;
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Container(
              height: 4,
              color: colorScheme.surfaceContainerHighest,
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              width: constraints.maxWidth * progress,
              decoration: BoxDecoration(
                color: isUrgent ? colorScheme.error : colorScheme.primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
