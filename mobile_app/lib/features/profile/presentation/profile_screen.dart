import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_avatar.dart';
import '../../../core/utils/image_cropper_screen.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/link_mobile_bottom_sheet.dart';
import '../../directory/presentation/app_bottom_navigation.dart';
import '../../directory/presentation/my_family_provider.dart';
import '../../directory/presentation/family_tree_screen.dart';
import '../../directory/presentation/family_member_detail_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../directory/presentation/app_drawer.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? _uploadedImageUrl;
  String? _uploadError;

  Future<void> _pickAndUploadImage() async {
    try {
      // 1. Pick Image
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image == null) return;

      if (!mounted) return;
      final File? croppedFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => CropImageScreen(imageFile: File(image.path), isCircle: true),
        ),
      );

      if (croppedFile == null) return;

      setState(() {
        _isUploading = true;
        _uploadError = null;
      });

      final filename = 'avatar_${DateTime.now().millisecondsSinceEpoch}.png';
      const contentType = 'image/png';

      // 2. Fetch Pre-signed URL from Hono API
      final dio = ref.read(apiClientProvider);
      final presignedResponse = await dio.post('/upload/presigned-url', data: {
        'filename': filename,
        'contentType': contentType,
      });

      final uploadUrl = presignedResponse.data['uploadUrl'] as String;
      final publicUrl = presignedResponse.data['publicUrl'] as String;

      // 3. Upload file directly to Cloudflare R2 via pre-signed URL (PUT request)
      final bytes = await croppedFile.readAsBytes();
      
      // Use clean Dio instance without interceptors for direct R2 upload (to avoid injecting Authorization header to Cloudflare R2)
      final uploadDio = Dio();
      final uploadResponse = await uploadDio.put(
        uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': bytes.length,
          },
        ),
      );

      if (uploadResponse.statusCode == 200) {
        // Save the updated avatar URL to the backend database
        await ref.read(authProvider.notifier).updateAvatarUrl(publicUrl);

        setState(() {
          _uploadedImageUrl = publicUrl;
          _isUploading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded and profile updated successfully!')),
          );
        }
      } else {
        throw Exception('R2 upload returned code ${uploadResponse.statusCode}');
      }
    } catch (e) {
      setState(() {
        _uploadError = e.toString();
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final lang = ref.watch(languageStateProvider);
    final user = authState.user;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final myFamilyAsync = ref.watch(myFamilyProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(AppTranslations.get('profile', lang)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // User Avatar Section
            Center(
              child: Stack(
                children: [
                  AppAvatar(
                    name: user?.fullName ?? 'User',
                    imageUrl: _uploadedImageUrl ?? user?.avatarUrl,
                    radius: 60,
                    fontSize: 48,
                  ),
                  if (_isUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Upload button
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickAndUploadImage,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text(AppTranslations.get('upload_photo', lang)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(180, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            if (_uploadError != null) ...[
              const SizedBox(height: 8),
              Text(
                'Upload Error: $_uploadError',
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 32),
            
            // Details List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Name'),
                      subtitle: Text(user?.fullName ?? ''),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Email'),
                      subtitle: Text(user?.email ?? ''),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.phone_outlined),
                      title: const Text('Registered Mobile'),
                      subtitle: Text(
                        (user?.mobile != null && user!.mobile!.isNotEmpty)
                            ? user.mobile!
                            : 'Not linked yet',
                        style: TextStyle(
                          color: (user?.mobile != null && user!.mobile!.isNotEmpty)
                              ? null
                              : colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                      trailing: (user?.mobile == null || user!.mobile!.isEmpty)
                          ? TextButton.icon(
                              onPressed: () => LinkMobileBottomSheet.show(context),
                              icon: const Icon(Icons.link_rounded, size: 16),
                              label: const Text('Link Now'),
                            )
                          : const Icon(Icons.verified_user_outlined, color: Colors.green, size: 20),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: Text(AppTranslations.get('role', lang)),
                      subtitle: Text(
                        user?.role == 'moderator'
                            ? AppTranslations.get('role_coordinator', lang)
                            : user?.role == 'admin'
                                ? AppTranslations.get('role_admin', lang)
                                : AppTranslations.get('role_member', lang),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    myFamilyAsync.when(
                      data: (data) {
                        if (data == null || data['member'] == null) {
                          return const SizedBox.shrink();
                        }
                        final memberData = data['member'];
                        final memberId = memberData['id'] as int;
                        final familyId = memberData['familyId'] as int;
                        return Column(
                          children: [
                            const Divider(),
                            ListTile(
                              leading: Icon(Icons.contact_page_outlined, color: colorScheme.primary),
                              title: const Text('My Directory Profile'),
                              subtitle: const Text('View your public directory card & family details'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () async {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(child: CircularProgressIndicator()),
                                );
                                try {
                                  final tree = await ref.read(familyTreeProvider(familyId).future);
                                  if (!context.mounted) return;
                                  Navigator.pop(context); // close loader
                                  
                                  final myMemberNode = tree.members.firstWhere((m) => m.id == memberId);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FamilyMemberDetailScreen(
                                        member: myMemberNode,
                                        familyMembers: tree.members,
                                        familyId: familyId,
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error loading profile: $e')),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Language Selection Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.language_rounded, color: colorScheme.secondary),
                        const SizedBox(width: 8),
                        Text(
                          AppTranslations.get('change_language', lang),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(AppTranslations.get('switch_english', lang)),
                      trailing: lang == AppLanguage.en ? Icon(Icons.check, color: colorScheme.secondary) : null,
                      onTap: () {
                        ref.read(languageStateProvider.notifier).setLanguage(AppLanguage.en);
                        ref.read(authProvider.notifier).changePreferredLanguage('en');
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: Text(AppTranslations.get('switch_hindi', lang)),
                      trailing: lang == AppLanguage.hi ? Icon(Icons.check, color: colorScheme.secondary) : null,
                      onTap: () {
                        ref.read(languageStateProvider.notifier).setLanguage(AppLanguage.hi);
                        ref.read(authProvider.notifier).changePreferredLanguage('hi');
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Legal & Support Card
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.volunteer_activism_outlined, color: colorScheme.primary),
                      title: Text(AppTranslations.get('donate', lang)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => context.push('/donate'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.help_outline, color: colorScheme.primary),
                      title: Text(AppTranslations.get('help_support', lang)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => context.push('/help-support'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.shield_outlined, color: colorScheme.primary),
                      title: Text(AppTranslations.get('privacy_policy', lang)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => context.push('/privacy-policy'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.gavel_outlined, color: colorScheme.primary),
                      title: Text(AppTranslations.get('terms_of_service', lang)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => context.push('/terms-and-conditions'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Danger Zone / Account Management Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.red.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          AppTranslations.get('danger_zone', lang),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lang == AppLanguage.hi
                          ? 'खाता हटाने पर आपके लॉगिन क्रेडेंशियल नष्ट हो जाएंगे, परंतु परिवार वृक्ष में आपकी डायरेक्टरी प्रविष्टि सुरक्षित रहेगी।'
                          : 'Deleting your account purges your login credentials and notification tokens. Your directory profile will remain preserved in the family tree.',
                      style: GoogleFonts.inter(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _confirmDeleteAccount(lang),
                        icon: const Icon(Icons.delete_forever_outlined),
                        label: Text(
                          AppTranslations.get('delete_account', lang),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 4),
    );
  }

  Future<void> _confirmDeleteAccount(AppLanguage lang) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppTranslations.get('delete_account_dialog_title', lang),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          AppTranslations.get('delete_account_dialog_desc', lang),
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppTranslations.get('cancel', lang)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppTranslations.get('delete_account_confirm', lang)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final success = await ref.read(authProvider.notifier).deleteAccount();

      if (mounted) {
        Navigator.pop(context); // Close loading indicator
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppTranslations.get('delete_success', lang)),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/login');
        } else {
          final errorMsg = ref.read(authProvider).errorMessage ?? 'Failed to delete account.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

