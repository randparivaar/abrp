import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/name_formatter.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../family_approval_detail_screen.dart';

class AdminFamilyApprovalsTab extends ConsumerStatefulWidget {
  const AdminFamilyApprovalsTab({super.key});

  @override
  ConsumerState<AdminFamilyApprovalsTab> createState() => _AdminFamilyApprovalsTabState();
}

class _AdminFamilyApprovalsTabState extends ConsumerState<AdminFamilyApprovalsTab> {
  List<dynamic> _pendingFamiliesList = [];
  bool _isLoadingPendingFamilies = true;
  String? _pendingFamiliesError;

  @override
  void initState() {
    super.initState();
    _fetchPendingFamilies();
  }

  Future<void> _fetchPendingFamilies() async {
    setState(() {
      _isLoadingPendingFamilies = true;
      _pendingFamiliesError = null;
    });
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/directory/moderation/pending-families');
      if (mounted) {
        setState(() {
          _pendingFamiliesList = (response.data['pendingFamilies'] as List<dynamic>? ?? []);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _pendingFamiliesError = 'Failed to load pending families: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPendingFamilies = false);
    }
  }

  Future<bool> _approveFamily(int familyId, String familyCode) async {
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post('/directory/moderation/family/$familyId/approve');
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Family $familyCode approved successfully!')),
          );
        }
        _fetchPendingFamilies();
        return true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Family approval failed: $e')),
        );
      }
    }
    return false;
  }

  Future<bool> _rejectFamily(int familyId, String familyCode, String reason) async {
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post('/directory/moderation/family/$familyId/reject', data: {
        'reason': reason.isNotEmpty ? reason : null,
      });
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Family $familyCode rejected.')),
          );
        }
        _fetchPendingFamilies();
        return true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Family rejection failed: $e')),
        );
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = ref.watch(languageStateProvider);

    if (_isLoadingPendingFamilies) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingFamiliesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_pendingFamiliesError!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchPendingFamilies,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pendingFamiliesList.isEmpty) {
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
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'There are no pending family approvals.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final isModerator = ref.watch(authProvider).user?.role == 'moderator';

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingFamiliesList.length + (isModerator ? 1 : 0),
      itemBuilder: (context, index) {
        if (isModerator && index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user_outlined, color: Colors.indigo.shade700, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppTranslations.get('coordinator_view_banner', lang),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.indigo.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final realIndex = isModerator ? index - 1 : index;
        final family = _pendingFamiliesList[realIndex] as Map<String, dynamic>;
        final familyId = family['familyId'] as int;
        final familyCode = family['familyCode'] as String;
        final headName = (family['headName'] as String? ?? '').toTitleCase();
        final villageName = family['villageName'] as String? ?? '';
        final regionName = family['regionName'] as String? ?? '';
        final totalMembers = family['totalMembers'] as int? ?? 0;
        final pendingCount = family['pendingCount'] as int? ?? 0;
        final rejectedCount = family['rejectedCount'] as int? ?? 0;

        return Card(
          elevation: 2,
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FamilyApprovalDetailScreen(
                    familyData: family,
                    onApprove: () => _approveFamily(familyId, familyCode),
                    onReject: (reason) => _rejectFamily(familyId, familyCode, reason),
                  ),
                ),
              ).then((_) {
                _fetchPendingFamilies();
              });
            },
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
                          familyCode,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$totalMembers Members',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.chevron_right, size: 20, color: colorScheme.primary),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    headName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$villageName ($regionName)',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (pendingCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$pendingCount Pending',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (rejectedCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$rejectedCount Rejected',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.touch_app_outlined, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'See full family details',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
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
