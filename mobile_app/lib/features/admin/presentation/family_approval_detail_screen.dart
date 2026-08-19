import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/name_formatter.dart';

class FamilyApprovalDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> familyData;
  final Future<bool> Function() onApprove;
  final Future<bool> Function(String reason) onReject;

  const FamilyApprovalDetailScreen({
    super.key,
    required this.familyData,
    required this.onApprove,
    required this.onReject,
  });

  @override
  ConsumerState<FamilyApprovalDetailScreen> createState() => _FamilyApprovalDetailScreenState();
}

class _FamilyApprovalDetailScreenState extends ConsumerState<FamilyApprovalDetailScreen> {
  bool _isProcessing = false;

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '';
    try {
      final dt = dateVal is DateTime ? dateVal : DateTime.parse(dateVal.toString());
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateVal.toString();
    }
  }

  String _formatAddress(Map<String, dynamic> data) {
    final parts = <String>[];
    final addr = data['address'] as String?;
    final city = data['city'] as String?;
    final state = data['state'] as String?;
    final pincode = data['pincode'] as String?;

    if (addr != null && addr.trim().isNotEmpty) parts.add(addr.trim());
    if (city != null && city.trim().isNotEmpty) parts.add(city.trim());
    if (state != null && state.trim().isNotEmpty) parts.add(state.trim());
    if (pincode != null && pincode.trim().isNotEmpty) parts.add('Pincode: ${pincode.trim()}');

    return parts.isNotEmpty ? parts.join(', ') : 'Not provided';
  }

  String _formatMemberAddress(Map<String, dynamic> m) {
    final parts = <String>[];
    final addr = m['currentAddress'] as String?;
    final city = m['currentCity'] as String?;
    final state = m['currentState'] as String?;
    final pincode = m['currentPincode'] as String?;

    if (addr != null && addr.trim().isNotEmpty) parts.add(addr.trim());
    if (city != null && city.trim().isNotEmpty) parts.add(city.trim());
    if (state != null && state.trim().isNotEmpty) parts.add(state.trim());
    if (pincode != null && pincode.trim().isNotEmpty) parts.add(pincode.trim());

    return parts.isNotEmpty ? parts.join(', ') : '';
  }

  void _showFullImageDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withValues(alpha: 0.92),
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        height: 250,
                        child: Center(child: CircularProgressIndicator(color: Colors.white)),
                      );
                    },
                    errorBuilder: (_, _, _) => Container(
                      padding: const EdgeInsets.all(32),
                      color: Colors.grey.shade900,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image, color: Colors.white54, size: 48),
                          SizedBox(height: 8),
                          Text('Failed to load image', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Entire Family?'),
        content: Text(
          'Are you sure you want to approve all members of family ${widget.familyData['familyCode']}?\n\n'
          'All members will become visible in the community directory.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('APPROVE FAMILY'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    final success = await widget.onApprove();
    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) Navigator.pop(context);
    }
  }

  Future<void> _handleReject() async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject Family ${widget.familyData['familyCode']}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please specify the reason for rejection so the family can update correct details.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason *',
                hintText: 'e.g. Incorrect Gotra, Photo missing for Head',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('REJECT FAMILY'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final reasonText = reasonController.text.trim();
    setState(() => _isProcessing = true);
    final success = await widget.onReject(reasonText);
    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final family = widget.familyData;
    final rawMembers = (family['members'] as List<dynamic>?) ?? [];

    // Sort members so that Family Head always appears first
    final sortedMembers = List<Map<String, dynamic>>.from(
      rawMembers.whereType<Map<String, dynamic>>(),
    );
    sortedMembers.sort((a, b) {
      final relA = (a['relationshipToHead'] as String? ?? '').toLowerCase();
      final relB = (b['relationshipToHead'] as String? ?? '').toLowerCase();
      final isHeadA = relA == 'head' || relA == 'self' || a['id'] == family['familyHeadId'];
      final isHeadB = relB == 'head' || relB == 'self' || b['id'] == family['familyHeadId'];
      if (isHeadA && !isHeadB) return -1;
      if (!isHeadA && isHeadB) return 1;
      return 0;
    });

    // Build a lookup map of memberId -> memberName for family relationships
    final memberMap = <dynamic, String>{};
    for (final member in sortedMembers) {
      final id = member['id'];
      final fn = member['fullName'] as String?;
      if (id != null && fn != null) {
        memberMap[id] = fn;
      }
    }

    // Find any existing rejection feedback
    String? existingFeedback;
    for (final m in sortedMembers) {
      final feedback = m['validationFeedback'] as String?;
      if (feedback != null && feedback.isNotEmpty) {
        existingFeedback = feedback;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Family Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${family['familyCode']} • ${family['headName']}', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing request...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Family Summary Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  family['familyCode'] as String? ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  _buildBadge('${family['totalMembers']} Members', Colors.blue),
                                  if ((family['pendingCount'] as int? ?? 0) > 0) ...[
                                    const SizedBox(width: 4),
                                    _buildBadge('${family['pendingCount']} Pending', Colors.orange),
                                  ],
                                  if ((family['rejectedCount'] as int? ?? 0) > 0) ...[
                                    const SizedBox(width: 4),
                                    _buildBadge('${family['rejectedCount']} Rejected', Colors.red),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(Icons.person_outline, 'Family Head', (family['headName'] as String? ?? '').toTitleCase()),
                          if (family['headMobile'] != null)
                            _buildDetailRow(Icons.phone_outlined, 'Head Mobile', family['headMobile'] as String),
                          _buildDetailRow(Icons.location_city_outlined, 'Native Village / Zone', '${family['villageName']} (${family['regionName']})'),
                          _buildDetailRow(Icons.home_outlined, 'Address', _formatAddress(family)),
                        ],
                      ),
                    ),
                  ),

                  // 2. Existing Rejection Notice Banner (if any)
                  if (existingFeedback != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Previous Rejection Reason:',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  existingFeedback,
                                  style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  Text(
                    'Family Members (${sortedMembers.length})',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // 3. Members Detailed List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedMembers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final m = sortedMembers[index];
                      return _buildMemberDetailCard(context, m, memberMap);
                    },
                  ),
                  const SizedBox(height: 80), // spacing for bottom bar
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
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
                  onPressed: _isProcessing ? null : _handleReject,
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('REJECT FAMILY', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _handleApprove,
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('APPROVE FAMILY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberDetailCard(BuildContext context, Map<String, dynamic> m, Map<dynamic, String> memberMap) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = (m['fullName'] as String? ?? '').toTitleCase();
    final rel = (m['relationshipToHead'] as String? ?? 'other').toUpperCase();
    final gender = (m['gender'] as String? ?? '').toUpperCase();
    final status = (m['status'] as String? ?? 'pending').toLowerCase();
    final avatarUrl = m['avatarUrl'] as String?;

    final isHead = rel == 'HEAD' || rel == 'SELF' || (m['id'] != null && m['id'] == widget.familyData['familyHeadId']);

    final email = m['email'] as String?;
    final mobile = m['mobile'] as String?;
    final whatsapp = m['whatsappMobile'] as String?;
    final gotra = m['gotra'] as String?;
    final bloodGroup = m['bloodGroup'] as String?;
    final maritalStatus = m['maritalStatus'] as String?;
    final education = m['education'] as String?;
    final occupationType = m['occupationType'] as String?;
    final occupationDetail = m['occupationDetail'] as String?;
    final income = m['yearlyIncome'];
    final remarks = m['specialRemarks'] as String?;
    final age = m['estimatedAgeOnCreation'];
    final birthYear = m['estimatedBirthYear'];
    final memberAddr = _formatMemberAddress(m);

    final isAlive = m['isAlive'] as bool? ?? true;
    final birthDateFormatted = _formatDate(m['birthDate']);
    final anniversaryDateFormatted = _formatDate(m['anniversaryDate']);
    final deceasedDateFormatted = _formatDate(m['deceasedDate']);

    final fatherName = m['fatherId'] != null ? memberMap[m['fatherId']]?.toTitleCase() : null;
    final motherName = m['motherId'] != null ? memberMap[m['motherId']]?.toTitleCase() : null;
    final spouseName = m['spouseId'] != null ? memberMap[m['spouseId']]?.toTitleCase() : null;

    Color statusColor = Colors.orange;
    if (status == 'approved') statusColor = Colors.green;
    if (status == 'rejected') statusColor = Colors.red;

    return Card(
      elevation: isHead ? 3 : 1,
      color: isHead
          ? (theme.brightness == Brightness.dark
              ? colorScheme.surfaceContainerHigh
              : Colors.amber.shade50.withValues(alpha: 0.4))
          : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isHead
            ? BorderSide(color: Colors.amber.shade700, width: 2.0)
            : BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: GestureDetector(
          onTap: avatarUrl != null && avatarUrl.isNotEmpty
              ? () => _showFullImageDialog(context, avatarUrl, name)
              : null,
          child: Tooltip(
            message: avatarUrl != null && avatarUrl.isNotEmpty ? 'Tap to view full image' : '',
            child: Container(
              padding: isHead ? const EdgeInsets.all(2) : EdgeInsets.zero,
              decoration: isHead
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber.shade700, width: 2),
                    )
                  : null,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null || avatarUrl.isEmpty ? Text(name.isNotEmpty ? name[0] : '?') : null,
                  ),
                  if (avatarUrl != null && avatarUrl.isNotEmpty)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.zoom_in, size: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            if (isHead) const Text('👑 ', style: TextStyle(fontSize: 14)),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isHead ? Colors.amber.shade900 : null,
                ),
              ),
            ),
            if (isHead)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFFF8C00)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium, size: 12, color: Colors.white),
                    SizedBox(width: 3),
                    Text(
                      'FAMILY HEAD',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Text('Gender: $gender', style: const TextStyle(fontSize: 12)),
            if (age != null) Text(' • Age: ~$age yrs', style: const TextStyle(fontSize: 12)),
            if (!isAlive) ...[
              const SizedBox(width: 4),
              _buildBadge('DECEASED', Colors.grey.shade700),
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  children: [
                    if (email != null && email.isNotEmpty) _buildInfoItem('Email', email),
                    if (mobile != null && mobile.isNotEmpty) _buildInfoItem('Mobile', mobile),
                    if (whatsapp != null && whatsapp.isNotEmpty) _buildInfoItem('WhatsApp', whatsapp),
                    if (gotra != null && gotra.isNotEmpty) _buildInfoItem('Gotra', gotra),
                    if (bloodGroup != null && bloodGroup.isNotEmpty) _buildInfoItem('Blood Group', bloodGroup),
                    if (maritalStatus != null && maritalStatus.isNotEmpty) _buildInfoItem('Marital Status', maritalStatus.toUpperCase()),
                    if (anniversaryDateFormatted.isNotEmpty) _buildInfoItem('Anniversary Date', anniversaryDateFormatted),
                    if (birthDateFormatted.isNotEmpty) _buildInfoItem('Date of Birth', birthDateFormatted),
                    if (age != null && birthYear != null) _buildInfoItem('Est. Birth Year', '$birthYear'),
                    if (fatherName != null) _buildInfoItem('Father', fatherName),
                    if (motherName != null) _buildInfoItem('Mother', motherName),
                    if (spouseName != null) _buildInfoItem('Spouse', spouseName),
                    if (!isAlive) _buildInfoItem('Vital Status', 'Deceased'),
                    if (!isAlive && deceasedDateFormatted.isNotEmpty) _buildInfoItem('Deceased Date', deceasedDateFormatted),
                    if (education != null && education.isNotEmpty) _buildInfoItem('Education', education),
                    if (occupationType != null && occupationType.isNotEmpty)
                      _buildInfoItem('Occupation', occupationDetail != null && occupationDetail.isNotEmpty ? '$occupationType ($occupationDetail)' : occupationType),
                    if (income != null) _buildInfoItem('Yearly Income', '₹$income'),
                  ],
                ),
                if (memberAddr.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildInfoItem('Current Address', memberAddr),
                ],
                if (remarks != null && remarks.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildInfoItem('Special Remarks', remarks),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 1),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
