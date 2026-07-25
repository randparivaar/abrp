import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/core/utils/app_avatar.dart';
import 'package:mobile_app/core/utils/name_formatter.dart';
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

  void _openWhatsApp(BuildContext context, String mobile) {
    final cleanMobile = mobile.replaceAll(RegExp(r'[+\s]+'), '');
    _launchURL(context, 'https://wa.me/$cleanMobile');
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasPerk = widget.business.communityPerk != null && 
        (widget.business.communityPerk!['value'] as String? ?? '').isNotEmpty;
    final perkType = widget.business.communityPerk?['type'] as String? ?? 'percent';
    final perkValue = widget.business.communityPerk?['value'] as String? ?? '';
    final perkDesc = widget.business.communityPerk?['description'] as String? ?? '';

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.business.logoUrl != null && widget.business.logoUrl!.isNotEmpty)
                    Image.network(
                      widget.business.logoUrl!,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: getAvatarBgColor(widget.business.businessName),
                      child: Center(
                        child: Text(
                          widget.business.businessName.isNotEmpty ? widget.business.businessName[0].toUpperCase() : 'B',
                          style: GoogleFonts.inter(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black54],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.business.businessName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300, width: 0.5),
                        ),
                        child: Text(
                          widget.business.industryCategory.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickAction(
                        context,
                        icon: Icons.phone_outlined,
                        label: 'Call',
                        onTap: () => _callPhone(context, widget.business.contactMobile),
                        color: colorScheme.primary,
                      ),
                      if (widget.business.whatsappMobile != null && widget.business.whatsappMobile!.isNotEmpty)
                        _buildQuickAction(
                          context,
                          icon: Icons.chat_outlined,
                          label: 'WhatsApp',
                          onTap: () => _openWhatsApp(context, widget.business.whatsappMobile!),
                          color: Colors.green.shade600,
                        ),
                      if (widget.business.email != null && widget.business.email!.isNotEmpty)
                        _buildQuickAction(
                          context,
                          icon: Icons.mail_outline,
                          label: 'Email',
                          onTap: () => _launchURL(context, 'mailto:${widget.business.email!}'),
                          color: Colors.blue.shade600,
                        ),
                      if (widget.business.websiteUrl != null && widget.business.websiteUrl!.isNotEmpty)
                        _buildQuickAction(
                          context,
                          icon: Icons.language_outlined,
                          label: 'Website',
                          onTap: () => _launchURL(context, widget.business.websiteUrl!),
                          color: Colors.purple.shade600,
                        ),
                      if (widget.business.googleMapsLink != null && widget.business.googleMapsLink!.isNotEmpty)
                        _buildQuickAction(
                          context,
                          icon: Icons.map_outlined,
                          label: 'Directions',
                          onTap: () => _launchURL(context, widget.business.googleMapsLink!),
                          color: Colors.red.shade600,
                        ),
                    ],
                  ),
                  const Divider(height: 32),

                  if (widget.business.description != null && widget.business.description!.isNotEmpty) ...[
                    Text(
                      'About / व्यवसाय के बारे में',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.secondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.business.description!,
                      style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (hasPerk) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade600, Colors.orange.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.shade800.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.white, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Samaj Discount Offer / समाज विशेष छूट',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                perkType == 'percent'
                                    ? '$perkValue%'
                                    : (perkType == 'fixed' ? '₹$perkValue' : 'OFFER'),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                perkType == 'percent' ? 'Discount for Samaj Members' : 'Flat Off for Samaj',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                          if (perkDesc.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              perkDesc,
                              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (widget.business.catalog != null && widget.business.catalog!.isNotEmpty) ...[
                    Text(
                      'Catalog / उत्पाद और सेवाएं',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.secondary),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
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
                            width: 140,
                            margin: const EdgeInsets.only(right: 12),
                            child: Card(
                              elevation: 0,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: Container(
                                      color: colorScheme.surfaceContainerLow,
                                      child: img.isNotEmpty
                                          ? Image.network(img, fit: BoxFit.cover)
                                          : const Icon(Icons.image_outlined, size: 28),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (desc.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            desc,
                                            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
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
                    const SizedBox(height: 20),
                  ],

                  // ── Associated Partners Section ───────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Partners & Owners / साझेदार और स्वामी',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: colorScheme.secondary,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _showAssignMemberSheet,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add / जोड़ें', style: TextStyle(fontSize: 12)),
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
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'No partners linked yet / कोई साझेदार लिंक नहीं है',
                              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
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
                                color: colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colorScheme.outlineVariant, width: 0.5),
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
                                  style: TextStyle(fontSize: 11, color: colorScheme.primary),
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

                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on_outlined, color: colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Store Location / स्टोर स्थान',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.secondary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${widget.business.address}, ${widget.business.city}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    if (widget.business.pincode != null)
                                      Text(
                                        'Pincode: ${widget.business.pincode}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (widget.business.operatingHours != null) ...[
                            const Divider(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.access_time_outlined, color: colorScheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Operating Hours / संचालन का समय',
                                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.secondary),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Days: ${widget.business.operatingHours!['days'] ?? "Mon - Sat"}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      Text(
                                        'Timings: ${widget.business.operatingHours!['open'] ?? "10:00 AM"} - ${widget.business.operatingHours!['close'] ?? "08:30 PM"}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (widget.business.gstin != null && widget.business.gstin!.isNotEmpty) ...[
                            const Divider(height: 24),
                            Row(
                              children: [
                                Icon(Icons.receipt_long_outlined, color: colorScheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'GSTIN: ${widget.business.gstin!}',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.secondary),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.isPending
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
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

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
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
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Map<String, dynamic>? _selectedMember;
  String _selectedRole = 'Partner';

  final List<String> _roles = ['Owner', 'Partner', 'Manager', 'Employee', 'Consultant'];

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/api/v1/directory/members/search', queryParameters: {'q': query});
      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          _searchResults = response.data['members'] as List<dynamic>;
        });
      }
    } catch (e) {
      debugPrint('Error searching members: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _submitAssignment() async {
    if (_selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a member to assign / कृपया जोड़ने के लिए सदस्य का चयन करें')),
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
              'Assign Partner / Owner\nसाझेदार/स्वामी को जोड़ें',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Search input field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search member by name / नाम से खोजें',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _performSearch,
            ),
            const SizedBox(height: 12),

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
                            'Relation: ${_selectedMember!['relationshipToHead'] ?? 'Member'}',
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
            ] else if (_searchResults.isNotEmpty) ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final m = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundImage: m['avatarUrl'] != null ? NetworkImage(m['avatarUrl']) : null,
                        child: m['avatarUrl'] != null ? null : Icon(m['gender'] == 'male' ? Icons.face : Icons.face_3, size: 16),
                      ),
                      title: Text(m['fullName'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text('Relation: ${m['relationshipToHead'] ?? ""}', style: const TextStyle(fontSize: 11)),
                      onTap: () {
                        setState(() {
                          _selectedMember = m;
                          _searchResults = [];
                          _searchController.clear();
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ] else if (_searchController.text.isNotEmpty && !_isSearching) ...[
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No members found / कोई सदस्य नहीं मिला', textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic)),
              ),
              const SizedBox(height: 16),
            ],

            // Role selection
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role in Business / व्यवसाय में भूमिका',
                border: OutlineInputBorder(),
              ),
              items: [..._roles, 'Other'].map((r) {
                return DropdownMenuItem<String>(
                  value: r,
                  child: Text(r),
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
              onPressed: _submitAssignment,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Add Member / सदस्य को शामिल करें'),
            ),
          ],
        ),
      ),
    );
  }
}
