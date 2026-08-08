import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'name_formatter.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final double? fontSize;
  final Color? backgroundColor;
  final Color? textColor;
  final BoxBorder? border;

  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 24,
    this.fontSize,
    this.backgroundColor,
    this.textColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final bgColor = backgroundColor ?? getAvatarBgColor(name);
    final calculatedFontSize = fontSize ?? (radius * 0.85);

    Widget fallbackChild = Text(
      initial,
      style: GoogleFonts.inter(
        color: textColor ?? Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: calculatedFontSize,
      ),
    );

    Widget avatarCore;
    if (hasImage) {
      avatarCore = CachedNetworkImage(
        imageUrl: imageUrl!.trim(),
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundColor: bgColor,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey.shade200,
          child: SizedBox(
            width: radius,
            height: radius,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: radius,
          backgroundColor: bgColor,
          child: fallbackChild,
        ),
      );
    } else {
      avatarCore = CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: fallbackChild,
      );
    }

    if (border != null) {
      return Container(
        padding: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: border,
        ),
        child: avatarCore,
      );
    }

    return avatarCore;
  }
}
