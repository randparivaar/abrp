import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/name_formatter.dart';
import '../../../directory/presentation/business_profile_detail_screen.dart';
import '../../../directory/presentation/family_tree_screen.dart';

class AdminBusinessApprovalsTab extends ConsumerStatefulWidget {
  const AdminBusinessApprovalsTab({super.key});

  @override
  ConsumerState<AdminBusinessApprovalsTab> createState() => _AdminBusinessApprovalsTabState();
}

class _AdminBusinessApprovalsTabState extends ConsumerState<AdminBusinessApprovalsTab> {
  List<dynamic> _pendingBusinessesList = [];
  bool _isLoadingPendingBusinesses = true;
  String? _pendingBusinessesError;

  @override
  void initState() {
    super.initState();
    _fetchPendingBusinesses();
  }

  Future<void> _fetchPendingBusinesses() async {
    setState(() {
      _isLoadingPendingBusinesses = true;
      _pendingBusinessesError = null;
    });
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/directory/moderation/pending-businesses');
      if (mounted) {
        setState(() {
          _pendingBusinessesList = (response.data['pendingBusinesses'] as List<dynamic>? ?? []);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _pendingBusinessesError = 'Failed to load pending businesses: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPendingBusinesses = false);
    }
  }

  Future<bool> _approveBusiness(int businessId, String businessName) async {
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post('/directory/moderation/business/$businessId/approve');
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$businessName has been approved.')),
          );
        }
        _fetchPendingBusinesses();
        return true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval failed: $e')),
        );
      }
    }
    return false;
  }

  Future<bool> _rejectBusiness(int businessId, String businessName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text('Reject $businessName?'),
          content: const Text('Are you sure you want to reject and delete this business profile?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('REJECT', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return false;

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post('/directory/moderation/business/$businessId/reject');
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$businessName has been rejected.')),
          );
        }
        _fetchPendingBusinesses();
        return true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rejection failed: $e')),
        );
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoadingPendingBusinesses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingBusinessesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_pendingBusinessesError!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchPendingBusinesses,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pendingBusinessesList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'All caught up!',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'There are no pending business approvals.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingBusinessesList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _pendingBusinessesList[index];
        final id = item['id'] as int;
        final businessName = item['businessName'] as String;
        final industryCategory = item['industryCategory'] as String;
        final contactMobile = item['contactMobile'] as String;
        final email = item['email'] as String?;
        final websiteUrl = item['websiteUrl'] as String?;
        final address = item['locationAddress'] as String?;
        final city = item['locationCity'] as String?;
        final state = item['locationState'] as String?;
        final pincode = item['locationPincode'] as String?;
        final ownerName = item['ownerName'] as String?;

        String fullAddress = '';
        if (address != null && address.isNotEmpty) {
          fullAddress = address;
          if (city != null && city.isNotEmpty) fullAddress += ', $city';
          if (state != null && state.isNotEmpty) fullAddress += ', $state';
          if (pincode != null && pincode.isNotEmpty) fullAddress += ' - $pincode';
        }

        return Card(
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              final bp = BusinessProfile(
                id: id,
                businessName: businessName,
                industryCategory: industryCategory,
                contactMobile: contactMobile,
                email: email,
                websiteUrl: websiteUrl,
                description: item['description'] as String?,
                address: address ?? '',
                city: city ?? '',
                state: state,
                pincode: pincode,
              );
              MemberNode? ownerNode;
              if (ownerName != null && ownerName.isNotEmpty && item['ownerId'] != null) {
                ownerNode = MemberNode(
                  id: item['ownerId'] as int,
                  familyId: -1,
                  fullName: ownerName,
                  gender: '',
                  relationshipToHead: 'self',
                );
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BusinessProfileDetailScreen(
                    business: bp,
                    owner: ownerNode,
                    isPending: true,
                    onApprove: () => _approveBusiness(id, businessName),
                    onReject: () => _rejectBusiness(id, businessName),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          businessName.toTitleCase(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              industryCategory.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 20, color: colorScheme.primary),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (ownerName != null && ownerName.isNotEmpty) ...[
                    Text('Owner: $ownerName'),
                    const SizedBox(height: 4),
                  ],
                  Text('Mobile: $contactMobile'),
                  if (email != null && email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Email: $email'),
                  ],
                  if (websiteUrl != null && websiteUrl.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Website: $websiteUrl'),
                  ],
                  if (fullAddress.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Address: $fullAddress'),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.touch_app_outlined, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Tap card to view full details',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _rejectBusiness(id, businessName),
                        icon: const Icon(Icons.close, size: 16, color: Colors.red),
                        label: const Text('Reject', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          minimumSize: const Size(120, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _approveBusiness(id, businessName),
                        icon: const Icon(Icons.check, size: 16, color: Colors.white),
                        label: const Text('Approve', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(120, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
