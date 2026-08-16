import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'directory_models.dart';

String resolveAdImageUrl(String? rawUrl) {
  if (rawUrl == null) return '';
  String url = rawUrl.trim();
  if (url.isEmpty) return '';

  // Replace localhost or 127.0.0.1 with 10.0.2.2 for Android emulator compatibility
  url = url
      .replaceAll('localhost', '10.0.2.2')
      .replaceAll('127.0.0.1', '10.0.2.2');

  if (url.startsWith('/')) {
    url = 'http://10.0.2.2:8005$url';
  }
  return url;
}

class AdBannerCard extends StatelessWidget {
  final AdvertisementModel ad;
  final double height;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  const AdBannerCard({
    super.key,
    required this.ad,
    this.height = 120,
    this.margin = EdgeInsets.zero,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedUrl = resolveAdImageUrl(ad.imageUrl);
    final hasImage = formattedUrl.isNotEmpty;

    return Container(
      margin: margin,
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: GestureDetector(
          onTap: onTap ??
              () {
                if (ad.targetUrl != null && ad.targetUrl!.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Opening ${ad.title}...')),
                  );
                }
              },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image or Fallback container
              if (hasImage)
                CachedNetworkImage(
                  imageUrl: formattedUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFFFFFDF5),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Image.network(
                    formattedUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (c, e, s) => Container(
                      color: const Color(0xFFFFFDF5),
                      child: const Icon(
                        Icons.campaign,
                        color: Color(0xFF795900),
                        size: 36,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  color: const Color(0xFFFFFDF5),
                  child: const Icon(
                    Icons.campaign,
                    color: Color(0xFF795900),
                    size: 36,
                  ),
                ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.72),
                      Colors.black.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              // Sponsored Badge and Ad details
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ad.category.isNotEmpty
                            ? 'SPONSORED · ${ad.category}'
                            : 'SPONSORED',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ad.title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ad.tagline != null && ad.tagline!.isNotEmpty)
                      Text(
                        ad.tagline!,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Swipeable Carousel widget for multiple ads (3 to 7+ ads) with page indicator dots
class AdBannerCarousel extends StatefulWidget {
  final List<AdvertisementModel> ads;
  final double height;
  final EdgeInsetsGeometry margin;

  const AdBannerCarousel({
    super.key,
    required this.ads,
    this.height = 120,
    this.margin = EdgeInsets.zero,
  });

  @override
  State<AdBannerCarousel> createState() => _AdBannerCarouselState();
}

class _AdBannerCarouselState extends State<AdBannerCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.ads.length > 1) {
      _startAutoSlide();
    }
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || widget.ads.length <= 1) return;
      final nextIndex = (_currentIndex + 1) % widget.ads.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ads.isEmpty) return const SizedBox.shrink();
    if (widget.ads.length == 1) {
      return AdBannerCard(
        ad: widget.ads.first,
        height: widget.height,
        margin: widget.margin,
      );
    }

    return Container(
      margin: widget.margin,
      height: widget.height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.ads.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return AdBannerCard(
                ad: widget.ads[index],
                height: widget.height,
              );
            },
          ),
          // Page Indicator Dots
          Positioned(
            bottom: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.ads.length, (index) {
                final isSelected = index == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 5,
                  width: isSelected ? 16 : 5,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.amber
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
