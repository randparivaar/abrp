import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_translations.dart';
import 'auth_controller.dart';

class LinkMobileBottomSheet extends ConsumerStatefulWidget {
  final bool isDismissible;
  const LinkMobileBottomSheet({super.key, this.isDismissible = true});

  static Future<void> show(BuildContext context, {bool isDismissible = true}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      backgroundColor: Colors.transparent,
      builder: (context) => LinkMobileBottomSheet(isDismissible: isDismissible),
    );
  }

  @override
  ConsumerState<LinkMobileBottomSheet> createState() => _LinkMobileBottomSheetState();
}

class _LinkMobileBottomSheetState extends ConsumerState<LinkMobileBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _submitMobile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final mobile = _mobileController.text.trim();
    final success = await ref.read(authProvider.notifier).linkMobileNumber(mobile);

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mobile number linked successfully! Profile synced with Family Directory.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final authState = ref.read(authProvider);
      setState(() {
        _errorMessage = authState.errorMessage ?? 'Could not link mobile number. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = ref.watch(languageStateProvider);
    final isHindi = lang == AppLanguage.hi;
    final primaryColor = theme.colorScheme.primary;
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── HANDLE BAR ───────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── HEADER ICON & TITLE ──────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.phone_android_rounded, color: primaryColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHindi ? 'मोबाइल नंबर लिंक करें' : 'Link Mobile Number',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          isHindi ? 'प्रोफ़ाइल जोड़ने के लिए' : 'To sync with Samaj Directory',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isDismissible)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // ── GOOGLE USER BADGE ────────────────────────────────────────
              if (user != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: primaryColor.withValues(alpha: 0.1),
                        backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                        child: user.avatarUrl == null
                            ? Icon(Icons.person, color: primaryColor, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              user.email,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── DESCRIPTION TEXT ─────────────────────────────────────────
              Text(
                isHindi
                    ? 'कृपया अपना 10-अंकीय मोबाइल नंबर दर्ज करें ताकि आपके गूगल खाते को आपके परिवार के पेड़ और समाज निर्देशिका के साथ जोड़ा जा सके।'
                    : 'Please enter your 10-digit mobile number to link your Google login to your family tree profile in the ABRP directory.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // ── MOBILE NUMBER INPUT FIELD ────────────────────────────────
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: isHindi ? 'मोबाइल नंबर (10 अंक)' : 'Mobile Number (10 digits)',
                  hintText: '9876543210',
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Text(
                      '+91',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return isHindi ? 'कृपया मोबाइल नंबर दर्ज करें' : 'Please enter mobile number';
                  }
                  final clean = val.trim();
                  if (clean.length < 10 || !RegExp(r'^[0-9]+$').hasMatch(clean)) {
                    return isHindi
                        ? 'अमान्य 10-अंकीय मोबाइल नंबर'
                        : 'Enter a valid 10-digit mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── ERROR MESSAGE ────────────────────────────────────────────
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── SUBMIT BUTTON ────────────────────────────────────────────
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitMobile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        isHindi ? 'लिंक करें और आगे बढ़ें' : 'Save & Link Profile',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),

              if (widget.isDismissible) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    isHindi ? 'बाद में करें' : 'Skip for now',
                    style: GoogleFonts.inter(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
