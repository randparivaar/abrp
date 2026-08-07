import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/core/utils/app_avatar.dart';
import 'package:go_router/go_router.dart';
import 'family_tree_screen.dart';
import 'family_member_detail_screen.dart';

class BusinessProfileDetailScreen extends ConsumerStatefulWidget {
  final BusinessProfile business;
  final MemberNode? owner; // Optional, represents the member associated with this business
  final bool isPending;
  final Future<bool?> Function()? onApprove;
  final Future<bool?> Function()? onReject;

  const BusinessProfileDetailScreen({
    super.key,
    required this.business,
    this.owner,
    this.isPending = false,
    this.onApprove,
    this.onReject,
  });

  @override
  ConsumerState<BusinessProfileDetailScreen> createState() => _BusinessProfileDetailScreenState();
}

class _BusinessProfileDetailScreenState extends ConsumerState<BusinessProfileDetailScreen> {
  List<dynamic> _members = [];
  bool _isLoadingMembers = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoadingMembers = true);
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/api/v1/directory/business/${widget.business.id}/members');
      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          _members = response.data['members'] as List<dynamic>;
        });
      }
    } catch (e) {
      debugPrint('Error fetching business members: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMembers = false);
    }
  }

  Future<void> _launchURL(BuildContext context, String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch $urlString');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open link / लिंक नहीं खोला जा सका: $e')),
        );
      }
    }
  }

  void _callPhone(BuildContext context, String mobile) {
    final cleanMobile = mobile.replaceAll(RegExp(r'\s+'), '');
    _launchURL(context, 'tel:$cleanMobile');
  }

  void _shareBusinessProfile() {
    final deepLink = 'abrp://business/${widget.business.id}';
    final shareText = '🏢 View ${widget.business.businessName}\'s profile on ABRP\n\n'
        'Category: ${widget.business.industryCategory}\n'
        'Address: ${widget.business.address}, ${widget.business.city}\n\n'
        'Open the ABRP app and tap this link to view business details:\n'
        '$deepLink';
    SharePlus.instance.share(
      ShareParams(
        text: shareText,
        subject: '${widget.business.businessName} - ABRP Business Profile',
      ),
    );
  }

  void _navigateToMember(int memberId, int familyId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final tree = await ref.read(familyTreeProvider(familyId).future);
      if (!mounted) return;
      Navigator.pop(context);

      final targetMember = tree.members.firstWhere((m) => m.id == memberId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FamilyMemberDetailScreen(
            member: targetMember,
            familyMembers: tree.members,
            familyId: familyId,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading member profile: $e')),
        );
      }
    }
  }

  void _showAssignMemberSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AssignMemberBottomSheet(
        businessId: widget.business.id,
        onSuccess: () {
          _fetchMembers();
        },
      ),
    );
  }

  Future<void> _unlinkMember(int memberId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Partner / साझेदार को हटाएं?'),
        content: const Text('Are you sure you want to remove this member from the business?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    // Call Delete API
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.delete('/api/v1/directory/business/${widget.business.id}/member/$memberId');
      if (!mounted) return;
      Navigator.pop(context); // Close loading spinner

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member removed successfully / सदस्य को सफलतापूर्वक हटा दिया गया है')),
        );
        _fetchMembers();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error unlinking member: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownerMember = widget.owner ?? 
        (_members.isNotEmpty && _members.any((m) => (m['roleInBusiness'] as String? ?? '').toLowerCase().contains('owner'))
            ? _members.firstWhere((m) => (m['roleInBusiness'] as String? ?? '').toLowerCase().contains('owner'))
            : null);

    final String? ownerName = widget.owner?.fullName ?? 
        (ownerMember is Map<String, dynamic> ? ownerMember['fullName'] as String? : null);
    final String ownerFirstName = ownerName != null && ownerName.isNotEmpty 
        ? '${ownerName.split(' ').first} ji' 
        : 'the business owner';

    final hasPerk = widget.business.communityPerk != null && 
        (widget.business.communityPerk!['value'] as String? ?? '').isNotEmpty;
    final perkType = widget.business.communityPerk?['type'] as String? ?? 'percent';
    final perkValue = widget.business.communityPerk?['value'] as String? ?? '';
    final perkDesc = widget.business.communityPerk?['description'] as String? ?? '';

    final hasDescription = widget.business.description != null && widget.business.description!.trim().isNotEmpty;
    final hasTags = widget.business.tags != null && widget.business.tags!.isNotEmpty;
    final hasCatalog = widget.business.catalog != null && widget.business.catalog!.isNotEmpty;
    final hasOperatingHours = widget.business.operatingHours != null && widget.business.operatingHours!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        scrolledUnderElevation: 1.0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B1C1C)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/business-directory');
            }
          },
        ),
        title: Text(
          widget.business.businessName,
          style: GoogleFonts.outfit(
            color: const Color(0xFF1B1C1C),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF4F4634)),
            tooltip: 'Share Profile',
            onPressed: _shareBusinessProfile,
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : const Color(0xFF4F4634),
            ),
            tooltip: 'Favorite',
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isFavorite 
                    ? 'Added to favorites / पसंदीदा में जोड़ा गया' 
                    : 'Removed from favorites / पसंदीदा से हटाया गया'),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── HERO BENTO COVER CARD ────────────────────────────
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
                    // Cover Image / Logo
                    if (widget.business.logoUrl != null && widget.business.logoUrl!.isNotEmpty)
                      Image.network(
                        widget.business.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFDAA520), Color(0xFF795900)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.storefront, size: 56, color: Colors.white),
                                const SizedBox(height: 8),
                                Text(
                                  widget.business.businessName,
                                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFDAA520), Color(0xFF795900)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.storefront, size: 56, color: Colors.white),
                              const SizedBox(height: 8),
                              Text(
                                widget.business.businessName,
                                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Gradient Overlay
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black87],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    // Owner Avatar Thumbnail & Info Overlay
                    Positioned(
                      left: 16,
                      bottom: 16,
                      right: 16,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (ownerName != null)
                            GestureDetector(
                              onTap: widget.owner != null 
                                ? () => _navigateToMember(widget.owner!.id, widget.owner!.familyId)
                                : null,
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: AppAvatar(
                                    name: ownerName,
                                    imageUrl: widget.owner?.avatarUrl,
                                    radius: 30,
                                  ),
                                ),
                              ),
                            ),
                          if (ownerName != null) const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.business.businessName,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDAA520),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.verified, size: 12, color: Color(0xFF553D00)),
                                          const SizedBox(width: 2),
                                          Text(
                                            'Verified',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF553D00),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (ownerName != null) ...[
                                  const SizedBox(height: 2),
                                  GestureDetector(
                                    onTap: widget.owner != null
                                      ? () => _navigateToMember(widget.owner!.id, widget.owner!.familyId)
                                      : null,
                                    child: Text(
                                      'Owner: $ownerName',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontWeight: FontWeight.w500,
                                        decoration: widget.owner != null ? TextDecoration.underline : TextDecoration.none,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── COMMUNITY CONNECT BENTO CARD (SAFFRON GOLD) ────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFDAA520),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDAA520).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Community Connect',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: const Color(0xFF553D00),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Connect directly with $ownerFirstName for custom orders and wholesale inquiries.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF553D00).withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _callPhone(context, widget.business.contactMobile),
                          icon: const Icon(Icons.call, size: 18, color: Colors.white),
                          label: Text(
                            'Call Now',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF553D00),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final mapUrl = widget.business.googleMapsLink ?? 
                                'https://maps.google.com/?q=${Uri.encodeComponent("${widget.business.businessName}, ${widget.business.address}, ${widget.business.city}")}';
                            _launchURL(context, mapUrl);
                          },
                          icon: const Icon(Icons.map_outlined, size: 18, color: Color(0xFF553D00)),
                          label: Text(
                            'View on Map',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF553D00)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── STANDALONE OPERATING HOURS CARD ──────────────────
            if (hasOperatingHours) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F3F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE4E2E1), width: 1),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.schedule, size: 32, color: Color(0xFF795900)),
                    const SizedBox(height: 8),
                    Text(
                      'Operating Hours',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xFF1B1C1C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.business.operatingHours!['days'] ?? "Mon - Sat"}: ${widget.business.operatingHours!['open'] ?? "10:00 AM"} - ${widget.business.operatingHours!['close'] ?? "08:30 PM"}',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4F4634)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Open Now',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: const Color(0xFF795900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── ABOUT BUSINESS SECTION & TAG CHIPS ───────────────
            if (hasDescription || hasTags) ...[
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Color(0xFF795900)),
                  const SizedBox(width: 8),
                  Text(
                    'About Business',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: const Color(0xFF795900),
                    ),
                  ),
                ],
              ),
              if (hasDescription) ...[
                const SizedBox(height: 8),
                Text(
                  widget.business.description!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: const Color(0xFF4F4634),
                  ),
                ),
              ],
              if (hasTags) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.business.tags!.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDAD4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8F0F07),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),
            ],

            // ── PRODUCTS & SERVICES SECTION ─────────────────────
            if (hasCatalog) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 20, color: Color(0xFF795900)),
                      const SizedBox(width: 8),
                      Text(
                        'Products & Services',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: const Color(0xFF795900),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Loading full product catalogue... / कैटलॉग लोड किया जा रहा है')),
                      );
                    },
                    child: Text(
                      'View All',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: const Color(0xFF795900),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 190,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.business.catalog!.length,
                  itemBuilder: (context, index) {
                    final item = widget.business.catalog![index] as Map<String, dynamic>;
                    final title = item['title'] as String? ?? 'Product';
                    final desc = item['description'] as String? ?? '';
                    final img = item['imageUrl'] as String? ?? '';

                    return Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 12),
                      child: Card(
                        elevation: 0,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE4E2E1), width: 0.8),
                        ),
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                color: const Color(0xFFF6F3F2),
                                child: img.isNotEmpty
                                    ? Image.network(
                                        img,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Center(child: Icon(Icons.image, color: Colors.grey)),
                                      )
                                    : const Center(child: Icon(Icons.shopping_bag, size: 32, color: Color(0xFF795900))),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1B1C1C)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (desc.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      desc,
                                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF4F4634)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── COMMUNITY PERK CARD (DEEP MAROON) ────────────────
            if (hasPerk) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFB22B1D),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB22B1D).withValues(alpha: 0.25),
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
                        const Icon(Icons.local_offer_outlined, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Community Perk',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            perkType == 'percent' ? '$perkValue%' : (perkType == 'fixed' ? '₹$perkValue' : 'OFFER'),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            'SPECIAL DISCOUNT',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                          if (perkDesc.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              perkDesc,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── CONTACT INFO & MEMBER TRUST CARD ────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F3F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE4E2E1), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Info',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF795900),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Location
                  InkWell(
                    onTap: () {
                      final mapUrl = widget.business.googleMapsLink ?? 
                          'https://maps.google.com/?q=${Uri.encodeComponent("${widget.business.address}, ${widget.business.city}")}';
                      _launchURL(context, mapUrl);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, color: Color(0xFF795900), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${widget.business.address}, ${widget.business.city}${widget.business.pincode != null ? ' - ${widget.business.pincode}' : ''}',
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4F4634), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Email
                  if (widget.business.email != null && widget.business.email!.isNotEmpty)
                    InkWell(
                      onTap: () => _launchURL(context, 'mailto:${widget.business.email!}'),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.mail_outline, color: Color(0xFF795900), size: 20),
                            const SizedBox(width: 10),
                            Text(
                              widget.business.email!,
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4F4634)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (widget.business.email != null && widget.business.email!.isNotEmpty)
                    const SizedBox(height: 8),

                  // Website
                  if (widget.business.websiteUrl != null && widget.business.websiteUrl!.isNotEmpty)
                    InkWell(
                      onTap: () => _launchURL(context, widget.business.websiteUrl!),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.language_outlined, color: Color(0xFF795900), size: 20),
                            const SizedBox(width: 10),
                            Text(
                              widget.business.websiteUrl!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF795900),
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const Divider(height: 24, color: Color(0xFFE4E2E1)),

                  // Trust Badges
                  Text(
                    'Verified Member Since 2018',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: const Color(0xFF4F4634),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 70,
                        height: 28,
                        child: Stack(
                          children: const [
                            Positioned(
                              left: 0,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Color(0xFFE0E0E0),
                                child: Icon(Icons.person, size: 16, color: Colors.grey),
                              ),
                            ),
                            Positioned(
                              left: 18,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Color(0xFFBDBDBD),
                                child: Icon(Icons.person, size: 16, color: Colors.white),
                              ),
                            ),
                            Positioned(
                              left: 36,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Color(0xFF795900),
                                child: Icon(Icons.person, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Trusted by 150+ members',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF4F4634),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── PARTNERS & OWNERS SECTION ────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Partners & Owners / साझेदार',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: const Color(0xFF795900),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showAssignMemberSheet,
                      icon: const Icon(Icons.add, size: 18, color: Color(0xFF795900)),
                      label: Text(
                        'Add / जोड़ें',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF795900)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (_isLoadingMembers)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_members.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F3F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'No partners linked yet / कोई साझेदार लिंक नहीं है',
                        style: GoogleFonts.inter(fontSize: 13, fontStyle: FontStyle.italic, color: const Color(0xFF4F4634)),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final m = _members[index];
                      final memberId = m['id'] as int;
                      final familyId = m['familyId'] as int;
                      final role = m['roleInBusiness'] as String? ?? 'Partner';
                      final avatarUrl = m['avatarUrl'] as String?;
                      final name = m['fullName'] as String? ?? 'Unknown';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F3F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE4E2E1), width: 0.8),
                        ),
                        child: ListTile(
                          leading: AppAvatar(
                            name: name,
                            imageUrl: avatarUrl,
                            radius: 20,
                          ),
                          title: Text(
                            name,
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Text(
                            role,
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF795900), fontWeight: FontWeight.w600),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios, size: 14),
                                onPressed: () => _navigateToMember(memberId, familyId),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                onPressed: () => _unlinkMember(memberId),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.isPending
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          if (widget.onReject != null) {
                            final res = await widget.onReject!();
                            if (res == true && context.mounted && Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          }
                        },
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Reject', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (widget.onApprove != null) {
                            final res = await widget.onApprove!();
                            if (res == true && context.mounted && Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          }
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _AssignMemberBottomSheet extends ConsumerStatefulWidget {
  final int businessId;
  final VoidCallback onSuccess;

  const _AssignMemberBottomSheet({
    required this.businessId,
    required this.onSuccess,
  });

  @override
  ConsumerState<_AssignMemberBottomSheet> createState() => _AssignMemberBottomSheetState();
}

class _AssignMemberBottomSheetState extends ConsumerState<_AssignMemberBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  
  List<dynamic> _eligibleMembers = [];
  List<dynamic> _filteredMembers = [];
  bool _isLoadingEligible = true;
  String? _eligibleError;
  Map<String, dynamic>? _selectedMember;
  String _selectedRole = 'Partner';

  final List<String> _roles = ['Owner', 'Partner', 'Manager', 'Employee', 'Consultant'];

  @override
  void initState() {
    super.initState();
    _fetchEligiblePartners();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _fetchEligiblePartners() async {
    setState(() {
      _isLoadingEligible = true;
      _eligibleError = null;
    });
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/api/v1/directory/business/${widget.businessId}/eligible-partners');
      if (response.statusCode == 200 && response.data != null) {
        final list = response.data['eligibleMembers'] as List<dynamic>? ?? [];
        setState(() {
          _eligibleMembers = list;
          _filteredMembers = list;
          _isLoadingEligible = false;
        });
      }
    } catch (e) {
      setState(() {
        _eligibleError = 'Failed to load family members: $e';
        _isLoadingEligible = false;
      });
    }
  }

  void _filterMembers(String query) {
    if (query.trim().isEmpty) {
      setState(() => _filteredMembers = _eligibleMembers);
    } else {
      final q = query.trim().toLowerCase();
      setState(() {
        _filteredMembers = _eligibleMembers.where((m) {
          final name = (m['fullName'] as String? ?? '').toLowerCase();
          final relation = (m['relationshipToHead'] as String? ?? '').toLowerCase();
          return name.contains(q) || relation.contains(q);
        }).toList();
      });
    }
  }

  Future<void> _submitAssignment() async {
    if (_selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a family member to assign / कृपया जोड़ने के लिए सदस्य का चयन करें')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post(
        '/api/v1/directory/business/${widget.businessId}/member',
        data: {
          'memberId': _selectedMember!['id'],
          'roleInBusiness': _selectedRole == 'Other' ? _roleController.text : _selectedRole,
        },
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading indicator

      if (response.statusCode == 200) {
        widget.onSuccess();
        Navigator.pop(context); // Close BottomSheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partner assigned successfully / साझेदार सफलतापूर्वक जोड़ दिया गया है')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning partner: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Assign Family Partner / Owner\nपारिवारिक साझेदार/स्वामी को जोड़ें',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🔒 Restricted to Business Owner & Family Members only',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoadingEligible)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_eligibleError != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_eligibleError!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              )
            else ...[
              // Search input field for filtering family members
              if (_eligibleMembers.length > 3)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search family member / परिवार सदस्य खोजें',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _filterMembers,
                  ),
                ),

              // Selected member card or results list
              if (_selectedMember != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.primary, width: 1),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: _selectedMember!['avatarUrl'] != null
                            ? NetworkImage(_selectedMember!['avatarUrl'])
                            : null,
                        child: _selectedMember!['avatarUrl'] != null
                            ? null
                            : Icon(_selectedMember!['gender'] == 'male' ? Icons.face : Icons.face_3),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedMember!['fullName'] ?? 'Unknown',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Relation: ${_selectedMember!['relationshipToHead'] ?? 'Family Member'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _selectedMember = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (_filteredMembers.isNotEmpty) ...[
                const Text('Select Family Member to Add:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _filteredMembers.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final m = _filteredMembers[index];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundImage: m['avatarUrl'] != null ? NetworkImage(m['avatarUrl']) : null,
                          child: m['avatarUrl'] != null ? null : Icon(m['gender'] == 'male' ? Icons.face : Icons.face_3, size: 16),
                        ),
                        title: Text(m['fullName'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text('Family Relation: ${m['relationshipToHead'] ?? "Member"}', style: const TextStyle(fontSize: 11)),
                        trailing: const Icon(Icons.add_circle_outline, color: Colors.teal),
                        onTap: () {
                          setState(() {
                            _selectedMember = m;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('All family members are already assigned or no eligible family members found.', textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                ),
                const SizedBox(height: 16),
              ],

              // Role selection
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Role in Business / व्यवसाय में भूमिका',
                  border: OutlineInputBorder(),
                ),
                items: [..._roles, 'Other'].map((r) {
                  return DropdownMenuItem<String>(
                    value: r,
                    child: Text(r, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedRole = val ?? 'Partner';
                  });
                },
              ),
              const SizedBox(height: 16),

              if (_selectedRole == 'Other') ...[
                TextField(
                  controller: _roleController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Custom Role / कस्टम भूमिका दर्ज करें',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              ElevatedButton(
                onPressed: _selectedMember != null ? _submitAssignment : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Add Family Partner / सदस्य को शामिल करें'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
