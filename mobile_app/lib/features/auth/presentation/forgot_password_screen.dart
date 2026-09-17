import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/core/localization/app_language.dart';
import 'package:mobile_app/core/localization/app_translations.dart';
import 'package:mobile_app/features/auth/presentation/auth_controller.dart';
import 'package:mobile_app/features/auth/presentation/login_screen.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).forgotPassword(email);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isOtpSent = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPass = _newPasswordController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).resetPassword(email, otp, newPass);
      if (mounted) {
        final lang = ref.read(languageStateProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang == AppLanguage.hi
                  ? 'पासवर्ड सफलतापूर्वक बदल दिया गया! कृपया नए पासवर्ड के साथ साइन इन करें।'
                  : 'Password reset successful! Please sign in with your new password.',
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageStateProvider);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;
    final isHindi = lang == AppLanguage.hi;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: primaryColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isHindi ? 'पासवर्ड रीसेट करें' : 'Forgot Password',
          style: GoogleFonts.outfit(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(languageStateProvider.notifier).setLanguage(
                    lang == AppLanguage.en ? AppLanguage.hi : AppLanguage.en,
                  );
            },
            child: Text(
              lang == AppLanguage.en ? 'हिन्दी' : 'EN',
              style: TextStyle(
                color: secondaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background Mandala Watermark
          Positioned.fill(
            child: CustomPaint(
              painter: MandalaWatermarkPainter(
                color: secondaryColor.withValues(alpha: 0.03),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: secondaryColor.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Icon
                          Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isOtpSent ? Icons.lock_reset_rounded : Icons.mark_email_unread_outlined,
                                color: primaryColor,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isOtpSent
                                ? (isHindi ? 'नया पासवर्ड दर्ज करें' : 'Verify & Set New Password')
                                : (isHindi ? 'पासवर्ड रीसेट' : 'Reset Your Password'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isOtpSent
                                ? (isHindi
                                    ? 'आपके ईमेल ${_emailController.text} पर भेजा गया 6-अंकों का कोड और नया पासवर्ड दर्ज करें।'
                                    : 'Enter the 6-digit OTP code sent to ${_emailController.text} and your new password.')
                                : (isHindi
                                    ? 'अपने पंजीकृत ईमेल दर्ज करें। हम आपको एक अस्थायी रीसेट कोड भेजेंगे।'
                                    : 'Enter your registered email address. We will send you a reset OTP code.'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Error alert banner
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: theme.colorScheme.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],



                          // Step 1: Email Field
                          TextFormField(
                            controller: _emailController,
                            readOnly: _isOtpSent,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.inter(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: isHindi ? 'ईमेल पता' : 'Email Address',
                              hintText: 'name@example.com',
                              prefixIcon: const Icon(Icons.mail_outline_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return isHindi ? 'कृपया ईमेल दर्ज करें' : 'Please enter email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                                return isHindi ? 'कृपया अमान्य ईमेल दर्ज करें' : 'Please enter valid email';
                              }
                              return null;
                            },
                          ),

                          if (_isOtpSent) ...[
                            const SizedBox(height: 16),

                            // OTP Code Field
                            TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              style: GoogleFonts.inter(fontSize: 16, letterSpacing: 4, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                labelText: isHindi ? '6-अंकों का ओटीपी' : '6-Digit OTP Code',
                                hintText: '123456',
                                counterText: '',
                                prefixIcon: const Icon(Icons.pin_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().length < 6) {
                                  return isHindi ? 'कृपया 6-अंकों का ओटीपी दर्ज करें' : 'Please enter 6-digit OTP';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // New Password Field
                            TextFormField(
                              controller: _newPasswordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.inter(fontSize: 14),
                              decoration: InputDecoration(
                                labelText: isHindi ? 'नया पासवर्ड' : 'New Password',
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return isHindi ? 'कृपया नया पासवर्ड दर्ज करें' : 'Please enter new password';
                                }
                                if (val.length < 6) {
                                  return isHindi ? 'कम से कम 6 अक्षर होने चाहिए' : 'Must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Submit Action Button
                          if (_isLoading)
                            Center(
                              child: CircularProgressIndicator(color: primaryColor),
                            )
                          else
                            ElevatedButton(
                              onPressed: _isOtpSent ? _handleResetPassword : _handleSendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _isOtpSent
                                    ? (isHindi ? 'पासवर्ड अपडेट करें' : 'Reset & Save Password')
                                    : (isHindi ? 'ओटीपी कोड प्राप्त करें' : 'Send Reset Code'),
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                          if (_isOtpSent) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isOtpSent = false;
                                  _otpController.clear();
                                  _newPasswordController.clear();
                                  _errorMessage = null;
                                });
                              },
                              child: Text(
                                isHindi ? 'अलग ईमेल दर्ज करें' : 'Use a different email',
                                style: TextStyle(color: secondaryColor, fontSize: 13),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
