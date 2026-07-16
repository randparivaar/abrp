import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'family_tree_screen.dart';
import 'business_profile_detail_screen.dart';
import 'package:intl/intl.dart';

class MemberProfileDetailScreen extends StatefulWidget {
  final MemberNode member;

  const MemberProfileDetailScreen({super.key, required this.member});

  @override
  State<MemberProfileDetailScreen> createState() => _MemberProfileDetailScreenState();
}

class _MemberProfileDetailScreenState extends State<MemberProfileDetailScreen> {
  bool _revealAadhaar = false;

  String _formatAadhaar(String? raw) {
    if (raw == null || raw.isEmpty) return 'Not Provided';
    final clean = raw.replaceAll(RegExp(r'\s+'), '');
    if (clean.length != 12) return raw;
    if (_revealAadhaar) {
      return '${clean.substring(0, 4)} ${clean.substring(4, 8)} ${clean.substring(8, 12)}';
    } else {
      return 'XXXX XXXX ${clean.substring(8, 12)}';
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard / क्लिपबोर्ड पर कॉपी किया गया'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final member = widget.member;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Member Profile / सदस्य प्रोफ़ाइल',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Profile Header Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.08),
                    colorScheme.secondary.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                children: [
                  // Hero Profile Photo
                  Hero(
                    tag: 'avatar_${member.id}',
                    child: Container(
                      padding: const EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.primary, width: 2.5),
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: member.gender == 'male' ? Colors.blue.shade50 : Colors.pink.shade50,
                        backgroundImage: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                            ? NetworkImage(member.avatarUrl!)
                            : null,
                        child: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                            ? null
                            : Icon(
                                member.gender == 'male' ? Icons.face : Icons.face_3,
                                color: member.gender == 'male' ? Colors.blue.shade400 : Colors.pink.shade400,
                                size: 54,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    member.fullName,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          member.relationshipToHead.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      if (member.bloodGroup != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.opacity, size: 12, color: Colors.red.shade700),
                              const SizedBox(width: 2),
                              Text(
                                member.bloodGroup!,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Colors.red.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Personal Information Card
                  _buildSectionCard(
                    title: 'Personal Info / व्यक्तिगत जानकारी',
                    icon: Icons.person_outline,
                    colorScheme: colorScheme,
                    children: [
                      _buildDetailItem(context, 'Gender / लिंग', member.gender.toUpperCase()),
                      _buildDetailItem(
                        context,
                        'Date of Birth / जन्मतिथि',
                        member.birthDate != null
                            ? DateFormat('dd MMM yyyy').format(member.birthDate!)
                            : (member.estimatedAgeOnCreation != null ? 'Age: ${member.estimatedAgeOnCreation} years (Est.)' : 'Not specified'),
                      ),
                      _buildDetailItem(context, 'Marital Status / वैवाहिक स्थिति', member.maritalStatus?.toUpperCase() ?? 'SINGLE'),
                      if (member.anniversaryDate != null)
                        _buildDetailItem(context, 'Anniversary Date / विवाह वर्षगांठ', DateFormat('dd MMM yyyy').format(member.anniversaryDate!)),
                      _buildDetailItem(context, 'Gotra / गोत्र', member.gotra ?? 'Not specified'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Contact & Address Card
                  _buildSectionCard(
                    title: 'Contact Details / संपर्क सूत्र',
                    icon: Icons.call_outlined,
                    colorScheme: colorScheme,
                    children: [
                      _buildDetailItem(
                        context,
                        'Mobile Number / मोबाइल नंबर',
                        member.mobile ?? 'Not specified',
                        trailing: member.mobile != null
                            ? IconButton(
                                icon: Icon(Icons.copy, size: 16, color: colorScheme.primary),
                                onPressed: () => _copyToClipboard(member.mobile!, 'Phone Number'),
                              )
                            : null,
                      ),
                      _buildDetailItem(
                        context,
                        'Address / पता',
                        member.currentAddress ?? 'Not specified',
                      ),
                      _buildDetailItem(
                        context,
                        'City & Pincode / शहर और पिनकोड',
                        '${member.currentCity ?? "Not specified"}${member.currentPincode != null ? " - ${member.currentPincode}" : ""}',
                      ),
                      _buildDetailItem(
                        context,
                        'State / राज्य',
                        member.currentState ?? 'Not specified',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Education & Profession Card
                  _buildSectionCard(
                    title: 'Education & Profession / शिक्षा और व्यवसाय',
                    icon: Icons.work_outline,
                    colorScheme: colorScheme,
                    children: [
                      _buildDetailItem(context, 'Education / शिक्षा', member.education ?? 'Not specified'),
                      _buildDetailItem(context, 'Occupation / पेशा', member.occupationType?.toUpperCase() ?? 'Not specified'),
                      if (member.occupationDetail != null)
                        _buildDetailItem(context, 'Occupation Details / विवरण', member.occupationDetail!),
                      if (member.yearlyIncome != null)
                        _buildDetailItem(
                          context,
                          'Yearly Income / वार्षिक आय',
                          '₹${NumberFormat.decimalPattern('en_IN').format(member.yearlyIncome)}',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4. Aadhaar & Special Remarks (Secure Layout)
                  _buildSectionCard(
                    title: 'Secure Details / संवेदनशील जानकारी',
                    icon: Icons.security_outlined,
                    colorScheme: colorScheme,
                    children: [
                      _buildDetailItem(
                        context,
                        'Aadhaar Number / आधार नंबर',
                        _formatAadhaar(member.aadhaarNo),
                        trailing: member.aadhaarNo != null && member.aadhaarNo!.isNotEmpty
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _revealAadhaar ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      size: 18,
                                      color: colorScheme.primary,
                                    ),
                                    onPressed: () => setState(() => _revealAadhaar = !_revealAadhaar),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.copy, size: 16, color: colorScheme.primary),
                                    onPressed: () => _copyToClipboard(member.aadhaarNo!, 'Aadhaar Card'),
                                  ),
                                ],
                              )
                            : null,
                      ),
                      if (member.specialRemarks != null && member.specialRemarks!.isNotEmpty) ...[
                        const Divider(height: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Special Remarks / विशेष टिप्पणी',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50.withValues(alpha: 0.5),
                                border: Border.all(color: Colors.amber.shade200, width: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: Colors.amber.shade800),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      member.specialRemarks!,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.brown.shade800,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  // 5. Linked Business Card
                  if (member.businessProfile != null) ...[
                    const SizedBox(height: 16),
                    _buildLinkedBusinessCard(context, member.businessProfile!, colorScheme),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required ColorScheme colorScheme,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value, {Widget? trailing}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          // ignore: use_null_aware_elements
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildLinkedBusinessCard(BuildContext context, BusinessProfile bp, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.2), width: 0.75),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BusinessProfileDetailScreen(business: bp, owner: widget.member),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Business Banner image
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                image: bp.logoUrl != null && bp.logoUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(bp.logoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: bp.logoUrl != null && bp.logoUrl!.isNotEmpty
                  ? const SizedBox.shrink()
                  : Center(
                      child: Icon(Icons.storefront_outlined, size: 48, color: colorScheme.primary.withValues(alpha: 0.4)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          bp.businessName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          bp.industryCategory.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (bp.description != null && bp.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      bp.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            bp.city,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Text(
                        'View Details / कार्ड देखें →',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
