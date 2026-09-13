import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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

class _OtpCardState extends State<OtpCard> {
  bool _copied = false;
  Timer? _copiedTimer;

  @override
  void dispose() {
    _copiedTimer?.cancel();
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
    final existingTheme = ShadTheme.maybeOf(context);
    final shadTheme = existingTheme ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppTheme.shadThemeDark(
                seedColor: Theme.of(context).colorScheme.primary,
              )
            : AppTheme.shadThemeLight(
                seedColor: Theme.of(context).colorScheme.primary,
              ));
    final isDark = shadTheme.brightness == Brightness.dark;

    final card = widget.compact
        ? _buildCompactCard(context, shadTheme, isDark)
        : _buildFullCard(context, shadTheme, isDark);

    if (existingTheme == null) {
      return ShadTheme(
        data: shadTheme,
        child: card,
      );
    }
    return card;
  }

  Widget _buildFullCard(
    BuildContext context,
    ShadThemeData shadTheme,
    bool isDark,
  ) {
    final account = widget.item.account;
    final code = widget.item.code;
    final borderColor = _copied
        ? shadTheme.colorScheme.primary
        : shadTheme.colorScheme.border;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _copyCode(context),
      onLongPress: widget.onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: ShadCard(
          radius: BorderRadius.circular(AppTheme.radiusSm),
          backgroundColor: shadTheme.colorScheme.card,
          border: ShadBorder.all(
            color: borderColor,
            width: _copied ? 1.5 : 1.0,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatar(shadTheme, account.issuer),
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
                                  color: shadTheme.colorScheme.foreground,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_copied) ...[
                              const SizedBox(width: 8),
                              ShadBadge.secondary(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.check,
                                      size: 11,
                                      color: shadTheme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Copied',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: shadTheme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account.accountLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: shadTheme.colorScheme.mutedForeground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (account.shortcutKey != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ShadBadge.secondary(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Text(
                          account.shortcutKey!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: shadTheme.colorScheme.mutedForeground,
                          ),
                        ),
                      ),
                    ),
                  _OtpCountdownRing(
                    period: account.period,
                    fallbackTimeLeft: code.timeLeft,
                  ),
                  if (widget.onEdit != null) ...[
                    const SizedBox(width: 6),
                    ShadButton.ghost(
                      size: ShadButtonSize.sm,
                      width: 32,
                      height: 32,
                      padding: EdgeInsets.zero,
                      onPressed: widget.onEdit,
                      child: Icon(
                        LucideIcons.ellipsisVertical,
                        size: 16,
                        color: shadTheme.colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _formatCode(code.code),
                    style: AppTheme.codeStyle(
                      color: shadTheme.colorScheme.foreground,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  ShadButton.outline(
                    size: ShadButtonSize.sm,
                    onPressed: () => _copyCode(context),
                    leading: Icon(
                      _copied ? LucideIcons.check : LucideIcons.copy,
                      size: 14,
                      color: _copied ? shadTheme.colorScheme.primary : shadTheme.colorScheme.foreground,
                    ),
                    child: Text(
                      _copied ? 'Copied' : 'Copy',
                      style: TextStyle(
                        color: _copied ? shadTheme.colorScheme.primary : shadTheme.colorScheme.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
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
    );
  }

  Widget _buildCompactCard(
    BuildContext context,
    ShadThemeData shadTheme,
    bool isDark,
  ) {
    final account = widget.item.account;
    final code = widget.item.code;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: ShadCard(
        radius: BorderRadius.circular(AppTheme.radiusSm),
        backgroundColor: shadTheme.colorScheme.card,
        border: ShadBorder.all(
          color: shadTheme.colorScheme.border,
          width: 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _copyCode(context),
          onLongPress: widget.onEdit,
          child: Row(
            children: [
              _buildAvatar(shadTheme, account.issuer, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.issuer,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: shadTheme.colorScheme.foreground,
                      ),
                    ),
                    Text(
                      _formatCode(code.code),
                      style: AppTheme.codeStyle(
                        color: shadTheme.colorScheme.foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _OtpCountdownRing(
                period: account.period,
                fallbackTimeLeft: code.timeLeft,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(
    ShadThemeData shadTheme,
    String issuer, {
    double size = 40,
  }) {
    final char = issuer.isNotEmpty ? issuer[0].toUpperCase() : '?';
    return ShadAvatar(
      null,
      size: Size.square(size),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      backgroundColor: shadTheme.colorScheme.primary,
      placeholder: Text(
        char,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: shadTheme.colorScheme.primaryForeground,
        ),
      ),
    );
  }

  String _formatCode(String code) {
    if (code.length == 6) {
      return '${code.substring(0, 3)} ${code.substring(3)}';
    } else if (code.length == 8) {
      return '${code.substring(0, 4)} ${code.substring(4)}';
    } else if (code.length > 3) {
      final mid = (code.length / 2).ceil();
      return '${code.substring(0, mid)} ${code.substring(mid)}';
    }
    return code;
  }
}

class _OtpCountdownRing extends ConsumerWidget {
  final int period;
  final int fallbackTimeLeft;
  final double size;

  const _OtpCountdownRing({
    required this.period,
    required this.fallbackTimeLeft,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickerAsync = ref.watch(totpTickerProvider);
    final currentSecond = tickerAsync.valueOrNull ??
        (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final timeLeft = calculateTimeLeft(period, currentSecond);
    final progress = calculateProgressFraction(period, currentSecond);
    final isUrgent = timeLeft <= 5;
    final shadTheme = ShadTheme.maybeOf(context) ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppTheme.shadThemeDark(
                seedColor: Theme.of(context).colorScheme.primary,
              )
            : AppTheme.shadThemeLight(
                seedColor: Theme.of(context).colorScheme.primary,
              ));

    final urgentColor = shadTheme.colorScheme.destructive;
    final ringColor = isUrgent ? urgentColor : shadTheme.colorScheme.primary;
    final trackColor = shadTheme.colorScheme.muted;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _CountdownRingPainter(
              progress: progress,
              ringColor: ringColor,
              trackColor: trackColor,
            ),
          ),
          Text(
            '$timeLeft',
            style: TextStyle(
              fontSize: size * 0.36,
              fontWeight: FontWeight.w700,
              color: ringColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;

  _CountdownRingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 2.5) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, trackPaint);

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(_CountdownRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.ringColor != ringColor ||
      oldDelegate.trackColor != trackColor;
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
    final currentSecond = tickerAsync.valueOrNull ??
        (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final timeLeft = calculateTimeLeft(period, currentSecond);
    final progress = calculateProgressFraction(period, currentSecond);
    final isUrgent = timeLeft <= 5;
    final shadTheme = ShadTheme.maybeOf(context) ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppTheme.shadThemeDark(
                seedColor: Theme.of(context).colorScheme.primary,
              )
            : AppTheme.shadThemeLight(
                seedColor: Theme.of(context).colorScheme.primary,
              ));

    return ShadProgress(
      value: progress.clamp(0.0, 1.0),
      minHeight: 4.0,
      color: isUrgent
          ? shadTheme.colorScheme.destructive
          : shadTheme.colorScheme.primary,
      backgroundColor: shadTheme.colorScheme.muted,
    );
  }
}
