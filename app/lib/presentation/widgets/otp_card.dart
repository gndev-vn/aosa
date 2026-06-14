import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../presentation/providers/otp_list_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
    final isUrgent = code.timeLeft <= 5;
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
          HapticFeedback.lightImpact();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _pulseController.reverse();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF232528) : Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                          Text(
                            account.issuer,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isUrgent
                            ? colorScheme.error.withAlpha(30)
                            : colorScheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${code.timeLeft}s',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isUrgent
                              ? colorScheme.error
                              : colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _formatCode(code.code),
                  style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 5,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
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
                          width: constraints.maxWidth * code.progress,
                          decoration: BoxDecoration(
                            color: isUrgent
                                ? colorScheme.error
                                : colorScheme.primary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme, String issuer) {
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
          issuer[0].toUpperCase(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context, ColorScheme colorScheme) {
    final account = widget.item.account;
    final code = widget.item.code;
    final isDark = colorScheme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _copyCode(context),
      onLongPress: widget.onEdit,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF232528) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAvatar(colorScheme, account.issuer),
              const SizedBox(height: 8),
              Text(
                account.issuer,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                _formatCode(code.code),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  fontFamily: 'monospace',
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: code.progress,
                  minHeight: 2,
                  color: code.timeLeft <= 5
                      ? colorScheme.error
                      : colorScheme.primary,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.item.code.code));
    HapticFeedback.heavyImpact();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Copied to clipboard'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatCode(String code) {
    if (code.length <= 3) return code;
    return '${code.substring(0, 3)} ${code.substring(3)}';
  }
}
