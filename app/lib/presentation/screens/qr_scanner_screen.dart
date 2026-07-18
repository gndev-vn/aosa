import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../widgets/corner_bracket_painter.dart';
import '../widgets/overlay_painter.dart';
import '../widgets/qr_action.dart';

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
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 20, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
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
                        child: QrAction(
                          icon: isOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          label: isOn ? 'Flash off' : 'Flash on',
                          onPressed: () => _cameraController.toggleTorch(),
                        ),
                      );
                    },
                  ),
                  QrAction(
                    icon: Icons.photo_library_rounded,
                    label: 'Pick from gallery',
                    onPressed: _pickFromGallery,
                  ),
                  const SizedBox(height: 12),
                  QrAction(
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
    const scanAreaSize = 260.0;
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
          painter: OverlayPainter(
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
              painter: CornerBracketPainter(
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
