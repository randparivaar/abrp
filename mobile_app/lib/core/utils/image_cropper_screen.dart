import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

class CropImageScreen extends StatefulWidget {
  final File imageFile;
  final bool isCircle;

  const CropImageScreen({
    super.key,
    required this.imageFile,
    this.isCircle = true,
  });

  @override
  State<CropImageScreen> createState() => _CropImageScreenState();
}

class _CropImageScreenState extends State<CropImageScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  int _rotationQuarter = 0;
  bool _isProcessing = false;

  Future<void> _cropAndSave() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // Use pixelRatio: 2.5 to get a nice high-resolution cropped image
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception("Failed to crop image data");

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      if (mounted) {
        Navigator.pop(context, file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cropping image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cropWidth = widget.isCircle ? 300.0 : 320.0;
    final cropHeight = widget.isCircle ? 300.0 : 160.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.isCircle ? 'Crop Profile / फोटो काटें' : 'Crop Banner / बैनर काटें',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_right, color: Colors.white),
            onPressed: () {
              setState(() {
                _rotationQuarter = (_rotationQuarter + 1) % 4;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Centered interactive image view
          Center(
            child: SizedBox(
              width: cropWidth,
              height: cropHeight,
              child: ClipRect(
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: Container(
                    color: Colors.black,
                    width: cropWidth,
                    height: cropHeight,
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 5.0,
                      boundaryMargin: const EdgeInsets.all(200.0),
                      clipBehavior: Clip.none,
                      child: RotatedBox(
                        quarterTurns: _rotationQuarter,
                        child: Image.file(
                          widget.imageFile,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Mask Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: CropMaskPainter(isCircle: widget.isCircle),
              ),
            ),
          ),
          // Loading spinner if processing
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Cancel / रद्द करें'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _cropAndSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Crop & Save / क्रॉप करें'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CropMaskPainter extends CustomPainter {
  final bool isCircle;

  CropMaskPainter({required this.isCircle});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);

    final Path maskPath = Path()..addRect(rect);
    final Path cutoutPath = Path();

    if (isCircle) {
      const radius = 150.0;
      cutoutPath.addOval(Rect.fromCircle(center: center, radius: radius));
    } else {
      const width = 320.0;
      const height = 160.0;
      cutoutPath.addRect(Rect.fromCenter(center: center, width: width, height: height));
    }

    canvas.drawPath(
      Path.combine(PathOperation.difference, maskPath, cutoutPath),
      paint,
    );

    // Border paint
    final borderPaint = Paint()
      ..color = Colors.amber.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (isCircle) {
      canvas.drawCircle(center, 150.0, borderPaint);
    } else {
      canvas.drawRect(Rect.fromCenter(center: center, width: 320.0, height: 160.0), borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CropMaskPainter oldDelegate) =>
      oldDelegate.isCircle != isCircle;
}
