import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';

String _formatHumanDate(DateTime? dt) {
  if (dt == null) return '';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
}

class AdminAdvertisementsTab extends ConsumerStatefulWidget {
  final ValueChanged<int>? onCountChanged;

  const AdminAdvertisementsTab({
    super.key,
    this.onCountChanged,
  });

  @override
  ConsumerState<AdminAdvertisementsTab> createState() => _AdminAdvertisementsTabState();
}

class _AdminAdvertisementsTabState extends ConsumerState<AdminAdvertisementsTab> {
  List<dynamic> _adminAdsList = [];
  bool _isLoadingAdminAds = false;

  @override
  void initState() {
    super.initState();
    _fetchAdminAds();
  }

  Future<void> _fetchAdminAds() async {
    setState(() => _isLoadingAdminAds = true);
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/ads/admin/all');
      if (response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _adminAdsList = response.data['ads'] as List<dynamic>;
          });
          widget.onCountChanged?.call(_adminAdsList.length);
        }
      }
    } catch (_) {
      // network / timeout — loader reset in finally
    } finally {
      if (mounted) setState(() => _isLoadingAdminAds = false);
    }
  }

  Future<void> _deleteAd(int adId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Advertisement?'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final dio = ref.read(apiClientProvider);
        await dio.delete('/ads/admin/$adId');
        _fetchAdminAds();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting ad: $e')));
        }
      }
    }
  }

  Future<void> _showAdFormModal({Map<String, dynamic>? ad}) async {
    final isEdit = ad != null;
    final titleCtrl =
        TextEditingController(text: ad?['title'] as String? ?? '');
    final taglineCtrl =
        TextEditingController(text: ad?['tagline'] as String? ?? '');
    final categoryCtrl =
        TextEditingController(text: ad?['category'] as String? ?? 'General');
    final targetUrlCtrl =
        TextEditingController(text: ad?['targetUrl'] as String? ?? '');
    final contactCtrl =
        TextEditingController(text: ad?['contactMobile'] as String? ?? '');
    final whatsappCtrl =
        TextEditingController(text: ad?['whatsappMobile'] as String? ?? '');
    final locationCtrl =
        TextEditingController(text: ad?['location'] as String? ?? '');
    final imageUrlCtrl =
        TextEditingController(text: ad?['imageUrl'] as String? ?? '');
    int priority = ad?['priority'] as int? ?? 0;
    bool isActive = ad?['isActive'] as bool? ?? true;
    DateTime? startDate = ad?['startDate'] != null
        ? DateTime.tryParse(ad!['startDate'].toString())
        : null;
    DateTime? endDate = ad?['endDate'] != null
        ? DateTime.tryParse(ad!['endDate'].toString())
        : null;

    final availablePlacements = [
      'home_carousel',
      'home_bottom_banner',
      'directory_header',
      'directory_feed',
      'business_native_catalog',
      'events_gallery',
      'community_feed',
    ];

    final Set<String> selectedPlacements = (ad?['placements'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toSet() ??
        {'home_carousel', 'directory_feed'};

    bool isUploading = false;

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Material(
              color: Theme.of(modalCtx).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Padding(
                padding: EdgeInsets.only(
                  top: 16,
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEdit
                                ? 'Edit Advertisement'
                                : 'Create New Advertisement',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Title / Business Name *',
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: taglineCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Tagline or Offer Description',
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: categoryCtrl,
                        decoration: const InputDecoration(
                            labelText:
                                'Category (e.g. Textiles, Healthcare, Food) *',
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      const Text('Image Banner:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (imageUrlCtrl.text.trim().isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            child: Image.network(
                              imageUrlCtrl.text.trim(),
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) =>
                                  const Center(child: Text('Invalid image URL')),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: imageUrlCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Image Banner URL',
                                border: OutlineInputBorder(),
                                hintText: 'https://...',
                              ),
                              onChanged: (v) => setModalState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: isUploading
                                ? null
                                : () async {
                                    try {
                                      final picker = ImagePicker();
                                      final image = await picker.pickImage(
                                          source: ImageSource.gallery,
                                          imageQuality: 85);
                                      if (image == null) return;

                                      setModalState(() => isUploading = true);

                                      final filename =
                                          'ad_${DateTime.now().millisecondsSinceEpoch}.jpg';
                                      const contentType = 'image/jpeg';

                                      final dio = ref.read(apiClientProvider);
                                      final presignedResponse =
                                          await dio.post('/upload/presigned-url',
                                              data: {
                                            'filename': filename,
                                            'contentType': contentType,
                                          });

                                      final uploadUrl = presignedResponse
                                          .data['uploadUrl'] as String;
                                      final publicUrl = presignedResponse
                                          .data['publicUrl'] as String;

                                      final bytes =
                                          await image.readAsBytes();
                                      final uploadDio = Dio();
                                      await uploadDio.put(
                                        uploadUrl,
                                        data: Stream.fromIterable([bytes]),
                                        options: Options(
                                          headers: {
                                            'Content-Type': contentType,
                                            'Content-Length': bytes.length,
                                          },
                                        ),
                                      );

                                      setModalState(() {
                                        imageUrlCtrl.text = publicUrl;
                                        isUploading = false;
                                      });

                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Banner image uploaded successfully!')),
                                        );
                                      }
                                    } catch (e) {
                                      setModalState(() => isUploading = false);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Image upload failed: $e')),
                                        );
                                      }
                                    }
                                  },
                            icon: isUploading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.upload_file, size: 18),
                            label: Text(
                                isUploading ? 'Uploading...' : 'Upload'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(90, 48),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      const Text('Target Placements (Multi-Select):',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: availablePlacements.map((placementKey) {
                          final isSelected =
                              selectedPlacements.contains(placementKey);
                          return FilterChip(
                            label: Text(placementKey,
                                style: const TextStyle(fontSize: 11)),
                            selected: isSelected,
                            onSelected: (val) {
                              setModalState(() {
                                if (val) {
                                  selectedPlacements.add(placementKey);
                                } else {
                                  selectedPlacements.remove(placementKey);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: contactCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                            labelText: 'Contact Mobile',
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: whatsappCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                            labelText: 'WhatsApp Mobile',
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: locationCtrl,
                        decoration: const InputDecoration(
                            labelText: 'City / Location',
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: targetUrlCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Target Website URL',
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                          'Time Period / Active Duration (Optional):',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(
                                startDate != null
                                    ? 'Start: ${_formatHumanDate(startDate)}'
                                    : 'Start Date',
                                style: const TextStyle(fontSize: 11),
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: modalCtx,
                                  initialDate: startDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setModalState(() => startDate = picked);
                                }
                              },
                            ),
                          ),
                          if (startDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () =>
                                  setModalState(() => startDate = null),
                            ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.event, size: 16),
                              label: Text(
                                endDate != null
                                    ? 'End: ${_formatHumanDate(endDate)}'
                                    : 'End Date',
                                style: const TextStyle(fontSize: 11),
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: modalCtx,
                                  initialDate: endDate ??
                                      DateTime.now().add(const Duration(days: 30)),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setModalState(() => endDate = picked);
                                }
                              },
                            ),
                          ),
                          if (endDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () =>
                                  setModalState(() => endDate = null),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          const Text('Active Status: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Switch(
                            value: isActive,
                            onChanged: (val) =>
                                setModalState(() => isActive = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (titleCtrl.text.trim().isEmpty ||
                                selectedPlacements.isEmpty) {
                              ScaffoldMessenger.of(modalCtx).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please provide title and select at least one placement.')),
                              );
                              return;
                            }

                            final payload = {
                              'title': titleCtrl.text.trim(),
                              'tagline': taglineCtrl.text.trim(),
                              'category': categoryCtrl.text.trim(),
                              'imageUrl': imageUrlCtrl.text.trim(),
                              'placements': selectedPlacements.toList(),
                              'contactMobile': contactCtrl.text.trim(),
                              'whatsappMobile': whatsappCtrl.text.trim(),
                              'location': locationCtrl.text.trim(),
                              'targetUrl': targetUrlCtrl.text.trim(),
                              'isActive': isActive,
                              'priority': priority,
                              'startDate': startDate?.toIso8601String(),
                              'endDate': endDate?.toIso8601String(),
                            };

                            try {
                              final dio = ref.read(apiClientProvider);
                              if (isEdit) {
                                await dio.put('/ads/admin/${ad['id']}',
                                    data: payload);
                              } else {
                                await dio.post('/ads/admin/create',
                                    data: payload);
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              _fetchAdminAds();
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                        content: Text('Error saving ad: $e')));
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary),
                          child: Text(
                              isEdit ? 'Update Campaign' : 'Publish Campaign',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
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

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(
              left: 16, right: 16, top: 16, bottom: 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ad Manager (${_adminAdsList.length})',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage active multi-placement community banners',
                        style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Ads',
                    onPressed: _fetchAdminAds,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_isLoadingAdminAds)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator()))
              else if (_adminAdsList.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 48, horizontal: 24),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: colorScheme.outlineVariant
                            .withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.campaign_outlined,
                          size: 56,
                          color: colorScheme.primary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('No Active Campaigns',
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(
                        'Tap the "+" button below to launch a new advertisement campaign.',
                        style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ..._adminAdsList.map((adItem) {
                  final adId = adItem['id'] as int;
                  final title = adItem['title'] as String? ?? '';
                  final category =
                      adItem['category'] as String? ?? 'General';
                  final isActive = adItem['isActive'] as bool? ?? true;
                  final priority = adItem['priority'] as int? ?? 0;
                  final placements =
                      (adItem['placements'] as List<dynamic>?)?.cast<String>() ??
                          [];
                  final tagline = adItem['tagline'] as String?;
                  final imageUrl = adItem['imageUrl'] as String?;
                  final location = adItem['location'] as String?;
                  final contactMobile =
                      adItem['contactMobile'] as String?;
                  final whatsappMobile =
                      adItem['whatsappMobile'] as String?;
                  final targetUrl = adItem['targetUrl'] as String?;
                  final startDate = adItem['startDate'] != null
                      ? DateTime.tryParse(adItem['startDate'].toString())
                      : null;
                  final endDate = adItem['endDate'] != null
                      ? DateTime.tryParse(adItem['endDate'].toString())
                      : null;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isActive
                            ? Colors.green.shade400
                            : colorScheme.outlineVariant,
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageUrl != null && imageUrl.trim().isNotEmpty)
                            Container(
                              height: 140,
                              width: double.infinity,
                              color: Colors.grey.shade200,
                              child: Image.network(
                                imageUrl.trim(),
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  color: Colors.grey.shade200,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image_outlined,
                                            color: Colors.grey.shade500),
                                        const SizedBox(height: 4),
                                        Text('Image load error',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color:
                                                    Colors.grey.shade600)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.green.shade100
                                            : Colors.grey.shade200,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isActive
                                                ? Icons.check_circle_rounded
                                                : Icons
                                                    .pause_circle_filled_rounded,
                                            size: 14,
                                            color: isActive
                                                ? Colors.green.shade800
                                                : Colors.grey.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isActive ? 'ACTIVE' : 'INACTIVE',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isActive
                                                  ? Colors.green.shade900
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Priority: $priority',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme
                                                .onSurfaceVariant),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          color: Colors.indigo),
                                      tooltip: 'Edit Campaign',
                                      onPressed: () =>
                                          _showAdFormModal(ad: adItem),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      tooltip: 'Delete Campaign',
                                      onPressed: () =>
                                          _deleteAd(adId, title),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  title,
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: colorScheme.onSurface),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colorScheme
                                            .primaryContainer,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        category,
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.primary),
                                      ),
                                    ),
                                    if (location != null &&
                                        location.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Icon(Icons.location_on_outlined,
                                          size: 14,
                                          color: colorScheme
                                              .onSurfaceVariant),
                                      const SizedBox(width: 2),
                                      Text(
                                        location,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme
                                                .onSurfaceVariant),
                                      ),
                                    ],
                                  ],
                                ),
                                if (tagline != null &&
                                    tagline.trim().isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.green.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.local_offer_outlined,
                                            size: 16,
                                            color: Colors.green.shade800),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            tagline,
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    Colors.green.shade900),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if ((contactMobile != null &&
                                        contactMobile.isNotEmpty) ||
                                    (whatsappMobile != null &&
                                        whatsappMobile.isNotEmpty) ||
                                    (targetUrl != null &&
                                        targetUrl.isNotEmpty) ||
                                    startDate != null ||
                                    endDate != null) ...[
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      if (startDate != null ||
                                          endDate != null)
                                        Chip(
                                          avatar: const Icon(
                                              Icons.date_range,
                                              size: 14,
                                              color: Colors.deepOrange),
                                          label: Text(
                                            'Period: ${startDate != null ? _formatHumanDate(startDate) : 'Immediate'} - ${endDate != null ? _formatHumanDate(endDate) : 'Indefinite'}',
                                            style:
                                                const TextStyle(fontSize: 11),
                                          ),
                                          visualDensity:
                                              VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                      if (contactMobile != null &&
                                          contactMobile.isNotEmpty)
                                        Chip(
                                          avatar: const Icon(Icons.phone,
                                              size: 14, color: Colors.blue),
                                          label: Text(contactMobile,
                                              style: const TextStyle(
                                                  fontSize: 11)),
                                          visualDensity:
                                              VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                      if (whatsappMobile != null &&
                                          whatsappMobile.isNotEmpty)
                                        Chip(
                                          avatar: const Icon(Icons.chat,
                                              size: 14,
                                              color: Colors.green),
                                          label: Text(whatsappMobile,
                                              style: const TextStyle(
                                                  fontSize: 11)),
                                          visualDensity:
                                              VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                      if (targetUrl != null &&
                                          targetUrl.isNotEmpty)
                                        Chip(
                                          avatar: const Icon(Icons.language,
                                              size: 14,
                                              color: Colors.purple),
                                          label: Text(targetUrl,
                                              style: const TextStyle(
                                                  fontSize: 11)),
                                          visualDensity:
                                              VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.layers_outlined,
                                        size: 16,
                                        color: colorScheme
                                            .onSurfaceVariant),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Target Placements:',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme
                                              .onSurfaceVariant),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: placements.map((p) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.shade50,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        border: Border.all(
                                            color: Colors.indigo.shade200),
                                      ),
                                      child: Text(
                                        p,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.indigo.shade900,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            onPressed: () => _showAdFormModal(),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('New Ad Campaign',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
