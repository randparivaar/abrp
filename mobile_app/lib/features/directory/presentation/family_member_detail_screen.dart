import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'family_tree_screen.dart';
import 'business_profile_detail_screen.dart';

class FamilyMemberDetailScreen extends StatelessWidget {
  final MemberNode member;
  final List<MemberNode> familyMembers;
  final int familyId;

  const FamilyMemberDetailScreen({
    super.key,
    required this.member,
    required this.familyMembers,
    required this.familyId,
  });

  String _formatDob(MemberNode m) {
    if (m.birthDate != null) {
      return DateFormat('dd MMM yyyy').format(m.birthDate!);
    }
    if (m.estimatedAgeOnCreation != null) {
      return 'Age ~${m.estimatedAgeOnCreation} yrs (Est.)';
    }
    return 'Not specified';
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _launchPhone(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchSms(String number) async {
    final uri = Uri(scheme: 'sms', path: number);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Other family members (exclude self)
    final others = familyMembers.where((m) => m.id != member.id).toList();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Member Profile',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: cs.primary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: cs.primary),
            onPressed: () {
              if (member.mobile != null) {
                _copyToClipboard(context, member.mobile!, 'Phone number');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero Section ──────────────────────────────────────────
            _HeroSection(member: member, onCall: _launchPhone, onSms: _launchSms),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Personal Information ──────────────────────────
                  _PersonalInfoCard(member: member, formatDob: _formatDob),
                  const SizedBox(height: 16),

                  // ── Contact Details ───────────────────────────────
                  _ContactDetailsCard(
                    member: member,
                    onCopy: (t, l) => _copyToClipboard(context, t, l),
                  ),
                  const SizedBox(height: 16),

                  // ── Immediate Family Members ───────────────────────
                  if (others.isNotEmpty) ...[
                    _ImmediateFamilyCard(
                      members: others,
                      familyId: familyId,
                      allMembers: familyMembers,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Business Profile ────────────────────────────────
                  if (member.businessProfile != null) ...[
                    _BusinessProfileCard(
                      business: member.businessProfile!,
                      member: member,
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Section
// ─────────────────────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final MemberNode member;
  final Future<void> Function(String) onCall;
  final Future<void> Function(String) onSms;

  const _HeroSection({
    required this.member,
    required this.onCall,
    required this.onSms,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final role = _roleLabel(member.relationshipToHead);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.10),
            cs.surface.withValues(alpha: 1.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Column(
        children: [
          // Avatar with role badge
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 136,
                height: 136,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cs.primaryContainer,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                      ? Image.network(
                          member.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _placeholderIcon(member, cs),
                        )
                      : _placeholderIcon(member, cs),
                ),
              ),
              // Role Badge
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.secondary,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    role,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: cs.onSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            member.fullName,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: cs.primary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          // Sub-label
          Text(
            'Maheshwari Community • Rander Parivar',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Action Buttons: Call / Email / Chat
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                icon: Icons.call_rounded,
                label: 'Call',
                cs: cs,
                onTap: member.mobile != null ? () => onCall(member.mobile!) : null,
              ),
              const SizedBox(width: 20),
              _ActionButton(
                icon: Icons.message_rounded,
                label: 'Chat',
                cs: cs,
                onTap: member.mobile != null ? () => onSms(member.mobile!) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholderIcon(MemberNode m, ColorScheme cs) {
    return Container(
      color: m.gender == 'male' ? Colors.blue.shade50 : Colors.pink.shade50,
      child: Icon(
        m.gender == 'male' ? Icons.face : Icons.face_3,
        size: 64,
        color: m.gender == 'male' ? Colors.blue.shade300 : Colors.pink.shade300,
      ),
    );
  }

  String _roleLabel(String rel) {
    switch (rel.toLowerCase()) {
      case 'self':
        return 'Family Head';
      case 'spouse':
        return 'Spouse';
      case 'son':
        return 'Son';
      case 'daughter':
        return 'Daughter';
      case 'father':
        return 'Father';
      case 'mother':
        return 'Mother';
      default:
        return rel.replaceAll('_', ' ').toUpperCase();
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.cs,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1.0,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: cs.onPrimaryContainer, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Personal Information Card
// ─────────────────────────────────────────────────────────────────────────────
class _PersonalInfoCard extends StatelessWidget {
  final MemberNode member;
  final String Function(MemberNode) formatDob;

  const _PersonalInfoCard({required this.member, required this.formatDob});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _SectionCard(
      icon: Icons.person_outlined,
      title: 'Personal Information',
      cs: cs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DOB
          _InfoRow(
            label: 'DATE OF BIRTH',
            value: formatDob(member),
            cs: cs,
          ),
          const SizedBox(height: 16),

          // Occupation
          _LabelText(label: 'OCCUPATION', cs: cs),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (member.occupationType != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    member.occupationType!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.tertiary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  member.occupationDetail ?? member.occupationType ?? 'Not specified',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Education
          _InfoRow(
            label: 'EDUCATION',
            value: member.education ?? 'Not specified',
            cs: cs,
          ),
          const SizedBox(height: 16),

          // Blood Group
          _LabelText(label: 'BLOOD GROUP', cs: cs),
          const SizedBox(height: 4),
          Text(
            member.bloodGroup ?? 'Not specified',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: member.bloodGroup != null ? cs.secondary : cs.onSurface,
            ),
          ),

          // Gotra
          if (member.gotra != null) ...[
            const SizedBox(height: 16),
            _InfoRow(label: 'GOTRA', value: member.gotra!, cs: cs),
          ],

          // Marital Status
          if (member.maritalStatus != null) ...[
            const SizedBox(height: 16),
            _InfoRow(
              label: 'MARITAL STATUS',
              value: member.maritalStatus!.toUpperCase(),
              cs: cs,
            ),
          ],

          // Anniversary
          if (member.anniversaryDate != null) ...[
            const SizedBox(height: 16),
            _InfoRow(
              label: 'ANNIVERSARY',
              value: DateFormat('dd MMM yyyy').format(member.anniversaryDate!),
              cs: cs,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contact Details Card
// ─────────────────────────────────────────────────────────────────────────────
class _ContactDetailsCard extends StatelessWidget {
  final MemberNode member;
  final void Function(String, String) onCopy;

  const _ContactDetailsCard({required this.member, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _SectionCard(
      icon: Icons.contact_page_outlined,
      title: 'Contact Details',
      cs: cs,
      child: Column(
        children: [
          // Phone
          _ContactRow(
            icon: Icons.phone_android_outlined,
            label: 'Primary Phone',
            value: member.mobile ?? 'Not specified',
            cs: cs,
            trailing: member.mobile != null
                ? IconButton(
                    icon: Icon(Icons.copy, size: 16, color: cs.primary),
                    onPressed: () => onCopy(member.mobile!, 'Phone'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : null,
          ),
          const SizedBox(height: 16),

          // Address
          _ContactRow(
            icon: Icons.location_on_outlined,
            label: 'Residential Address',
            value: _buildAddress(member),
            cs: cs,
          ),
        ],
      ),
    );
  }

  String _buildAddress(MemberNode m) {
    final parts = <String>[];
    if (m.currentAddress != null && m.currentAddress!.isNotEmpty) parts.add(m.currentAddress!);
    if (m.currentCity != null && m.currentCity!.isNotEmpty) parts.add(m.currentCity!);
    if (m.currentState != null && m.currentState!.isNotEmpty) parts.add(m.currentState!);
    if (m.currentPincode != null && m.currentPincode!.isNotEmpty) parts.add(m.currentPincode!);
    return parts.isEmpty ? 'Not specified' : parts.join(', ');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Immediate Family Members Card
// ─────────────────────────────────────────────────────────────────────────────
class _ImmediateFamilyCard extends StatelessWidget {
  final List<MemberNode> members;
  final int familyId;
  final List<MemberNode> allMembers;

  const _ImmediateFamilyCard({
    required this.members,
    required this.familyId,
    required this.allMembers,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.secondary.withValues(alpha: 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.family_restroom, size: 22, color: cs.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Immediate Family Members',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cs.secondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FamilyTreeScreen(familyId: familyId),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'View Family Tree',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: cs.primary,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: cs.primary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Horizontal scroll of member cards
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: members.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final m = members[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FamilyMemberDetailScreen(
                          member: m,
                          familyMembers: allMembers,
                          familyId: familyId,
                        ),
                      ),
                    ),
                    child: _FamilyMemberCard(member: m, cs: cs),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyMemberCard extends StatelessWidget {
  final MemberNode member;
  final ColorScheme cs;

  const _FamilyMemberCard({required this.member, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cs.primary, width: 2),
            ),
            child: ClipOval(
              child: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                  ? Image.network(
                      member.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(height: 8),

          // Name
          Text(
            member.fullName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.15,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),

          // Relationship
          Text(
            _relLabel(member.relationshipToHead),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: member.gender == 'male' ? Colors.blue.shade50 : Colors.pink.shade50,
      child: Icon(
        member.gender == 'male' ? Icons.face : Icons.face_3,
        size: 36,
        color: member.gender == 'male' ? Colors.blue.shade300 : Colors.pink.shade300,
      ),
    );
  }

  String _relLabel(String rel) {
    switch (rel.toLowerCase()) {
      case 'self':
        return 'Family Head';
      case 'spouse':
        return 'Spouse';
      case 'son':
        return 'Son';
      case 'daughter':
        return 'Daughter';
      case 'father':
        return 'Father';
      case 'mother':
        return 'Mother';
      default:
        return rel[0].toUpperCase() + rel.substring(1);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final ColorScheme cs;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.cs,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.secondary.withValues(alpha: 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 22, color: cs.secondary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;

  const _InfoRow({required this.label, required this.value, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabelText(label: label, cs: cs),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _LabelText extends StatelessWidget {
  final String label;
  final ColorScheme cs;

  const _LabelText({required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;
  final Widget? trailing;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: cs.outline),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                  color: cs.onSurface,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _BusinessProfileCard extends StatelessWidget {
  final BusinessProfile business;
  final MemberNode member;

  const _BusinessProfileCard({
    required this.business,
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Owned Business / व्यावसायिक प्रोफाइल',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: cs.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: business.logoUrl != null && business.logoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(business.logoUrl!, fit: BoxFit.cover),
                      )
                    : Icon(Icons.storefront, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.businessName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      business.industryCategory,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (business.description != null && business.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              business.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          const Divider(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BusinessProfileDetailScreen(
                    business: business,
                    owner: member,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('View Business Details / विवरण देखें'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
            ),
          ),
        ],
      ),
    );
  }
}
