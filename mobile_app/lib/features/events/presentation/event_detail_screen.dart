import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/features/events/domain/event_model.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  int _selectedImageIndex = 0;

  Future<void> _launchExternalUrl(BuildContext context, String urlString) async {
    final sanitized = DriveUrlHelper.sanitizeUrl(urlString);
    try {
      final Uri url = Uri.parse(sanitized);
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        final fallbackLaunched = await launchUrl(url, mode: LaunchMode.platformDefault);
        if (!fallbackLaunched) {
          throw Exception('Could not launch URL');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open link / लिंक नहीं खोला जा सका: $sanitized')),
        );
      }
    }
  }

  void _showFullScreenImageViewer(BuildContext context, List<String> images, int initialIndex) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        int currentIndex = initialIndex;
        final PageController controller = PageController(initialPage: initialIndex);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
                title: Text(
                  'Image ${currentIndex + 1} of ${images.length}',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                ),
              ),
              body: PageView.builder(
                controller: controller,
                itemCount: images.length,
                onPageChanged: (index) {
                  setDialogState(() {
                    currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    maxScale: 4.0,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: images[index],
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 64,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final allImages = widget.event.allImageUrls;
    final primaryImage = allImages.isNotEmpty ? allImages[_selectedImageIndex] : widget.event.imageUrl;
    final hasExternalAlbum = widget.event.externalAlbumUrl != null &&
        widget.event.externalAlbumUrl!.trim().isNotEmpty;

    final event = widget.event;
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final shortFormat = DateFormat('dd MMM');
    final isMultiDay = event.endDate != null &&
        !(event.endDate!.year == event.eventDate.year &&
          event.endDate!.month == event.eventDate.month &&
          event.endDate!.day == event.eventDate.day);
    final durationDays = isMultiDay
        ? event.endDate!.difference(event.eventDate).inDays + 1
        : null;

    // Build a human-readable date string
    final String dateDisplay = isMultiDay
        ? '${shortFormat.format(event.eventDate)} → ${DateFormat('dd MMM yyyy').format(event.endDate!)}'
        : '${dateFormat.format(event.eventDate)} • ${timeFormat.format(event.eventDate)}';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1.0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          'Event Details',
          style: GoogleFonts.outfit(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── HERO BANNER / IMAGE VIEWER CARD ─────────────────
            Container(
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (primaryImage != null && primaryImage.isNotEmpty)
                      GestureDetector(
                        onTap: () => _showFullScreenImageViewer(context, allImages, _selectedImageIndex),
                        child: CachedNetworkImage(
                          imageUrl: primaryImage,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFDAA520), Color(0xFF795900)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.event, size: 64, color: Colors.white),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFB22B1D), Color(0xFFDAA520)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.campaign_rounded, size: 64, color: Colors.white),
                              const SizedBox(height: 8),
                              Text(
                                widget.event.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Overlay Badge for Category
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDAA520),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Text(
                          widget.event.category.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF553D00),
                          ),
                        ),
                      ),
                    ),

                    // Zoom indicator hint
                    if (allImages.isNotEmpty)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${_selectedImageIndex + 1}/${allImages.length} (Tap to expand)',
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── MULTI-IMAGE THUMBNAIL GALLERY CAROUSEL ──────────
            if (allImages.length > 1) ...[
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: allImages.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedImageIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImageIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 70,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? colorScheme.primary : Colors.transparent,
                            width: isSelected ? 2.5 : 0,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: allImages[index],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── EVENT TITLE & METADATA CARD ──────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.title,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.calendar_month_rounded,
                          color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateDisplay,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (isMultiDay && durationDays != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: colorScheme.primary.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  '$durationDays-Day Event',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('EEEE, dd MMMM yyyy')
                                    .format(event.eventDate),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.event.venue != null && widget.event.venue!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_rounded, color: const Color(0xFFB22B1D), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.event.venue!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── EXTERNAL PHOTO ALBUM BENTO CARD (GOOGLE PHOTOS / DROPBOX / DRIVE) ─
            if (hasExternalAlbum) ...[
              Builder(
                builder: (context) {
                  final albumUrl = widget.event.externalAlbumUrl!.trim();
                  final isDrive = albumUrl.contains('drive.google.com');
                  final isPhotos = albumUrl.contains('photos.app.goo.gl') || albumUrl.contains('photos.google.com');
                  final isDropbox = albumUrl.contains('dropbox.com');

                  final String cardTitle = isDrive
                      ? 'Google Drive Photo Folder / ड्राइव फ़ोल्डर'
                      : (isPhotos
                          ? 'Google Photos Album / फ़ोटो एलबम'
                          : (isDropbox ? 'Dropbox Folder / ड्रॉपबॉक्स' : 'Full Event Photo Album'));

                  final String cardSubtitle = isDrive
                      ? 'View all high-resolution event photos directly on Google Drive.'
                      : (isPhotos
                          ? 'View all official event photos on Google Photos.'
                          : 'View all official high-resolution event photos directly on Google Photos, Dropbox, or Google Drive.');

                  final String buttonLabel = isDrive
                      ? '📁 Open Google Drive / ड्राइव में खोलें'
                      : (isPhotos
                          ? '📸 Open Google Photos / गूगल फ़ोटो में खोलें'
                          : '📸 Open Photo Album / फोटो एलबम खोलें');

                  final Color primaryAccent = isDrive ? const Color(0xFF0F9D58) : const Color(0xFF1E3A8A);

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDrive
                            ? [const Color(0xFF0F9D58), const Color(0xFF1B5E20)]
                            : (isPhotos
                                ? [const Color(0xFF4285F4), const Color(0xFF34A853)]
                                : [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)]),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryAccent.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(isDrive ? Icons.folder_shared_rounded : Icons.photo_library_rounded, color: Colors.white, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                cardTitle,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cardSubtitle,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _launchExternalUrl(context, albumUrl),
                          icon: Icon(Icons.open_in_new_rounded, size: 18, color: primaryAccent),
                          label: Text(
                            buttonLabel,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: primaryAccent,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // ── DESCRIPTION SECTION ─────────────────────────────
            if (widget.event.description != null && widget.event.description!.trim().isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.notes_rounded, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'About Event / विवरण',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? colorScheme.onSurface : colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surfaceContainer : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.event.description!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.6,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
