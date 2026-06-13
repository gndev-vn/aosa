import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  final ValueChanged<String> onScan;

  const QrScannerScreen({super.key, required this.onScan});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isProcessing = false;
  late final AnimationController _scanLineController;
  late final Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scanLineController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: (barcodeCapture) {
              if (_isProcessing) return;
              final barcode = barcodeCapture.barcodes.firstOrNull;
              final rawValue = barcode?.rawValue;
              if (rawValue != null && rawValue.isNotEmpty) {
                _isProcessing = true;
                HapticFeedback.heavyImpact();
                widget.onScan(rawValue);
              }
            },
            overlayBuilder: (context, constraints) =>
                _buildOverlay(theme, colorScheme, constraints),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 8,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(200),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Scan QR Code',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 32,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _cameraController,
                    builder: (context, state, child) {
                      if (state.torchState == TorchState.unavailable) {
                        return const SizedBox.shrink();
                      }
                      final isOn = state.torchState == TorchState.on;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _QrButton(
                          icon: isOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          label: isOn ? 'Flash off' : 'Flash on',
                          onPressed: () =>
                              _cameraController.toggleTorch(),
                        ),
                      );
                    },
                  ),
                  _QrButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Pick from gallery',
                    onPressed: _pickFromGallery,
                  ),
                  const SizedBox(height: 12),
                  _QrButton(
                    icon: Icons.edit_rounded,
                    label: 'Enter key manually',
                    onPressed: () => widget.onScan(
                      'otpauth://totp/Manual:placeholder?secret=',
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverlay(
    ThemeData theme,
    ColorScheme colorScheme,
    BoxConstraints constraints,
  ) {
    final scanAreaSize = 260.0;
    final left = (constraints.maxWidth - scanAreaSize) / 2;
    final top = (constraints.maxHeight - scanAreaSize) / 2 - 40;
    final scanRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize),
      const Radius.circular(20),
    );

    return Stack(
      children: [
        CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _OverlayPainter(
            scanRect: scanRect,
            color: Colors.black.withAlpha(160),
          ),
        ),
        Positioned(
          left: left - 3,
          top: top - 3,
          child: SizedBox(
            width: scanAreaSize + 6,
            height: scanAreaSize + 6,
            child: CustomPaint(
              painter: _CornerBracketPainter(
                color: colorScheme.primary,
                lineWidth: 3,
              ),
            ),
          ),
        ),
        Positioned(
          left: left + 6,
          top: top + 6,
          child: SizedBox(
            width: scanAreaSize - 12,
            height: scanAreaSize - 12,
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _scanLineAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      _scanLineAnimation.value * (scanAreaSize - 12),
                    ),
                    child: Container(
                      width: scanAreaSize - 12,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withAlpha(0),
                            colorScheme.primary,
                            colorScheme.primary.withAlpha(0),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: top + scanAreaSize + 20,
          child: Text(
            'Point camera at QR code',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;

    setState(() => _isProcessing = true);

    try {
      final barcode = await _cameraController.analyzeImage(xfile.path);
      if (!mounted) return;

      final rawValue = barcode?.barcodes.firstOrNull?.rawValue;
      if (rawValue != null) {
        widget.onScan(rawValue);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No QR code found in image')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read QR code: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

class _QrButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _QrButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white38),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final RRect scanRect;
  final Color color;

  _OverlayPainter({required this.scanRect, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final outerRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final outer = RRect.fromRectAndRadius(outerRect, Radius.zero);
    final path = Path()
      ..addRRect(outer)
      ..addRRect(scanRect);
    canvas.drawPath(
      Path.combine(PathOperation.reverseDifference, path, Path()..addRRect(scanRect)),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      old.scanRect != scanRect || old.color != color;
}

class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final double lineWidth;

  _CornerBracketPainter({required this.color, required this.lineWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;

    // Top-left
    canvas.drawLine(
      Offset(0, cornerLength),
      Offset(0, 0),
      paint,
    );
    canvas.drawLine(
      Offset(0, 0),
      Offset(cornerLength, 0),
      paint,
    );

    // Top-right
    canvas.drawLine(
      Offset(size.width - cornerLength, 0),
      Offset(size.width, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width, size.height - cornerLength),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - cornerLength, size.height),
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(cornerLength, size.height),
      Offset(0, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CornerBracketPainter old) => old.color != color;
}
