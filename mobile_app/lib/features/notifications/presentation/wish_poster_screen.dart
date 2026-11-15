import 'dart:io';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class WishPosterScreen extends StatefulWidget {
  final String? posterUrl;
  final String title;
  final String? body;
  final String? wishType; // 'festival', 'birthday', 'anniversary', 'announcement', 'general'
  final String? memberName;
  final String? spouseName;
  final String? avatarUrl;
  final String? coupleNames;

  const WishPosterScreen({
    super.key,
    this.posterUrl,
    required this.title,
    this.body,
    this.wishType,
    this.memberName,
    this.spouseName,
    this.avatarUrl,
    this.coupleNames,
  });

  @override
  State<WishPosterScreen> createState() => _WishPosterScreenState();
}

class _WishPosterScreenState extends State<WishPosterScreen> {
  final GlobalKey _posterKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _sharePoster() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/abrp_wish_${DateTime.now().millisecondsSinceEpoch}.png';

      // 1. If we have a direct poster image URL, download it directly for sharing
      if (widget.posterUrl != null && widget.posterUrl!.isNotEmpty) {
        final dio = Dio();
        final response = await dio.get<List<int>>(
          widget.posterUrl!,
          options: Options(responseType: ResponseType.bytes),
        );
        final file = File(filePath);
        await file.writeAsBytes(response.data!);

        final shareText = '${widget.title}\n\n'
            '${widget.body ?? ''}\n\n'
            '— अखिल भारतीय रांदेर परिवार समाज\n'
            'ABRP Samaj App पर देखें: https://api.abrp.walogics.in';

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath)],
            text: shareText,
            subject: widget.title,
          ),
        );
      } else {
        // 2. Render dynamic card widget to high-res PNG
        final boundary = _posterKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 3.0);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final pngBytes = byteData.buffer.asUint8List();
            final file = File(filePath);
            await file.writeAsBytes(pngBytes);

            final shareText = '${widget.title}\n\n'
                '${widget.body ?? ''}\n\n'
                '— समस्त रांदेर परिवार समाज\n'
                'ABRP Samaj App: https://api.abrp.walogics.in';

            await SharePlus.instance.share(
              ShareParams(
                files: [XFile(filePath)],
                text: shareText,
                subject: widget.title,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share poster: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasDirectPoster = widget.posterUrl != null && widget.posterUrl!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9F6F0),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
            tooltip: 'Share on WhatsApp',
            onPressed: _sharePoster,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.0,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: RepaintBoundary(
                      key: _posterKey,
                      child: hasDirectPoster
                          ? _buildImagePosterView()
                          : _buildDynamicWishCard(isDark),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: _isSharing ? null : _sharePoster,
                      icon: _isSharing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.share_rounded, size: 20),
                      label: Text(
                        'WhatsApp पर शेयर करें / Share',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePosterView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: CachedNetworkImage(
          imageUrl: widget.posterUrl!,
          fit: BoxFit.contain,
          placeholder: (ctx, url) => const SizedBox(
            height: 380,
            child: Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (ctx, url, err) => Container(
            height: 300,
            color: Colors.grey.shade200,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Could not load poster image'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicWishCard(bool isDark) {
    final isAnniversary = widget.wishType == 'anniversary';
    final hasAvatar = widget.avatarUrl != null && widget.avatarUrl!.trim().isNotEmpty;
    final name = widget.coupleNames ?? widget.memberName ?? 'आदरणीय स्वजन';

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAnniversary
              ? [const Color(0xFF6B1139), const Color(0xFF9F1239), const Color(0xFF4C0519)]
              : [const Color(0xFF1E3A8A), const Color(0xFF1E40AF), const Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFBBF24), width: 3), // Golden border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Corner Decorative Motifs
          Positioned(
            top: 10,
            left: 12,
            child: Text('🕉️', style: TextStyle(fontSize: 22, color: Colors.amber.shade200)),
          ),
          Positioned(
            top: 10,
            right: 12,
            child: Text('🌸', style: TextStyle(fontSize: 22, color: Colors.amber.shade200)),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Samaj Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 1),
                  ),
                  child: Text(
                    'अखिल भारतीय रांदेर परिवार समाज',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFEF3C7),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Center Photo Frame (or Floral Seal if no image uploaded)
                if (hasAvatar)
                  Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFBBF24), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFBBF24).withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: widget.avatarUrl!,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (ctx, url, err) => _buildDefaultSeal(isAnniversary),
                      ),
                    ),
                  )
                else
                  _buildDefaultSeal(isAnniversary),

                const SizedBox(height: 18),

                // Greeting Title
                Text(
                  isAnniversary
                      ? 'वैवाहिक वर्षगांठ की हार्दिक शुभकामनाएँ'
                      : 'जन्मदिन की हार्दिक शुभकामनाएँ',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFDE68A),
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),

                // Member Name / Couple Name Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Body Message
                Text(
                  widget.body ??
                      (isAnniversary
                          ? 'ईश्वर आपके दांपत्य जीवन को सदैव सुख, शांति, समृद्धि एवं उत्तम स्वास्थ्य से परिपूर्ण रखे।'
                          : 'ईश्वर से आपके उत्तम स्वास्थ्य, दीर्घायु एवं मंगलमय जीवन की प्रार्थना करते हैं।'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFE2E8F0),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite_rounded, size: 14, color: Color(0xFFFDE68A)),
                    const SizedBox(width: 6),
                    Text(
                      'समस्त रांदेर परिवार समाज',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFDE68A),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultSeal(bool isAnniversary) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
        border: Border.all(color: const Color(0xFFFBBF24), width: 3),
      ),
      child: Center(
        child: Text(
          isAnniversary ? '💍' : '🎂',
          style: const TextStyle(fontSize: 48),
        ),
      ),
    );
  }
}
