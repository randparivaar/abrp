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
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 4),
    );
  }
}
