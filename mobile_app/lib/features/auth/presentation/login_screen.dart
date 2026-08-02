import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_translations.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_isSignUp) {
      if (!_agreeToTerms) {
        final lang = ref.read(languageStateProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang == AppLanguage.hi
                  ? 'कृपया जारी रखने के लिए नियम और शर्तों से सहमत हों।'
                  : 'Please agree to the terms of service and privacy policy to continue.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
      final fullName = _fullNameController.text.trim();
      final mobile = _mobileController.text.trim();
      ref.read(authProvider.notifier).signUpWithEmail(email, fullName, password, mobile);
    } else {
      ref.read(authProvider.notifier).signInWithEmail(email, password);
    }
  }

  // Local localized strings helper
  String _getString(String key, AppLanguage lang) {
    final localized = {
      'welcome_title': {
        AppLanguage.en: 'Akhil Bhartiya Rander Parivar',
        AppLanguage.hi: 'रांदड़ परिवार समाज',
      },
      'welcome_subtitle': {
        AppLanguage.en: 'Welcome back to your community. Connect with your heritage and kin.',
        AppLanguage.hi: 'अपने समाज में आपका स्वागत है। अपनी विरासत और परिजनों से जुड़ें।',
      },
      'login_instruction': {
        AppLanguage.en: 'Login to your account',
        AppLanguage.hi: 'अपने खाते में लॉगिन करें',
      },
      'register_instruction': {
        AppLanguage.en: 'Create a new account',
        AppLanguage.hi: 'नया खाता बनाएं',
      },
      'email_label': {
        AppLanguage.en: 'Email Address',
        AppLanguage.hi: 'ईमेल पता',
      },
      'email_hint': {
        AppLanguage.en: 'name@example.com',
        AppLanguage.hi: 'name@example.com',
      },
      'mobile_label': {
        AppLanguage.en: 'Mobile Number',
        AppLanguage.hi: 'मोबाइल नंबर',
      },
      'mobile_hint': {
        AppLanguage.en: 'Enter 10-digit mobile number',
        AppLanguage.hi: '10 अंकों का मोबाइल नंबर दर्ज करें',
      },
      'password_label': {
        AppLanguage.en: 'Password',
        AppLanguage.hi: 'पासवर्ड',
      },
      'password_hint': {
        AppLanguage.en: '••••••••',
        AppLanguage.hi: '••••••••',
      },
      'fullname_label': {
        AppLanguage.en: 'Full Name',
        AppLanguage.hi: 'पूरा नाम',
      },
      'fullname_hint': {
        AppLanguage.en: 'Pura Naam (Full Name)',
        AppLanguage.hi: 'पूरा नाम दर्ज करें',
      },
      'forgot_password': {
        AppLanguage.en: 'Forgot Password?',
        AppLanguage.hi: 'पासवर्ड भूल गए?',
      },
      'login_btn': {
        AppLanguage.en: 'Sign In',
        AppLanguage.hi: 'साइन इन',
      },
      'register_btn': {
        AppLanguage.en: 'Sign Up',
        AppLanguage.hi: 'साइन अप',
      },
      'switch_signup_prompt': {
        AppLanguage.en: "Don't have an account? ",
        AppLanguage.hi: "अकाउंट नहीं है? ",
      },
      'switch_signup_btn': {
        AppLanguage.en: 'Sign Up',
        AppLanguage.hi: 'साइन अप',
      },
      'switch_login_prompt': {
        AppLanguage.en: 'Already have an account? ',
        AppLanguage.hi: 'पहले से अकाउंट है? ',
      },
      'switch_login_btn': {
        AppLanguage.en: 'Sign In',
        AppLanguage.hi: 'साइन इन',
      },
      'continue_with_google': {
        AppLanguage.en: 'Continue with Google',
        AppLanguage.hi: 'गूगल के साथ जारी रखें',
      },
      'or_divider': {
        AppLanguage.en: 'or',
        AppLanguage.hi: 'या',
      },
    };
    return localized[key]?[lang] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final lang = ref.watch(languageStateProvider);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary; // Gilded Saffron/Gold
    final secondaryColor = theme.colorScheme.secondary; // Deep Maroon
    final backgroundColor = theme.colorScheme.surface; // Light Cream (#fbf9f8)

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // 1. Traditional Watermark Mandala Patterns
          Positioned.fill(
            child: CustomPaint(
              painter: MandalaWatermarkPainter(
                color: secondaryColor.withValues(alpha: 0.03),
              ),
            ),
          ),

          // 2. Soft Backdrop Image from Design
          Positioned(
            bottom: -150,
            right: -150,
            child: Opacity(
              opacity: 0.10,
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDcp5muvArPz1Ujdhh1URklB_5aNFfdP1JByxiqCm8NYCumwKI7j2L1KyXWwnXflHi5zyKRKMFEYMdK3YQUEqnV2u8n6A07L0GjOZE2iRia0JuYRZN1_ZTQW-oEdRfn-Vmxrc_zq-qbisq8KSYg9JBBZ2u8oxX9Sitlja8GOsEVpGAN6QxnqcBmv9KdQcqwuws_t1Q16at5y3yrkkFEIK_r1Sm0VMY4xbUwDhJgxLPV5_Vwymc8eX5BlaBjj6EcHzbaurruFgEiNaM',
                width: 500,
                height: 500,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),

          // 3. Language Selector at Top Right
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: secondaryColor.withValues(alpha: 0.15), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => ref.read(languageStateProvider.notifier).setLanguage(AppLanguage.en),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'EN',
                          style: TextStyle(
                            color: lang == AppLanguage.en ? secondaryColor : Colors.black54,
                            fontWeight: lang == AppLanguage.en ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Container(
                        height: 12,
                        width: 1,
                        color: secondaryColor.withValues(alpha: 0.2),
                      ),
                      TextButton(
                        onPressed: () => ref.read(languageStateProvider.notifier).setLanguage(AppLanguage.hi),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'हिं',
                          style: TextStyle(
                            color: lang == AppLanguage.hi ? secondaryColor : Colors.black54,
                            fontWeight: lang == AppLanguage.hi ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Main Scrollable Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  // Card Container (Theme-adapted for light & dark mode)
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: secondaryColor.withValues(alpha: 0.15), width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Branding
                        Container(
                          padding: const EdgeInsets.only(top: 32, bottom: 24, left: 24, right: 24),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.03),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Emblem Icon
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer, // Gold container
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.account_balance_outlined,
                                    color: Color(0xFF553D00), // on-primary-container
                                    size: 36,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Title
                              Text(
                                _getString('welcome_title', lang),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  height: 36 / 28,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Subtitle
                              Text(
                                _getString('welcome_subtitle', lang),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 20 / 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Form & Action Contents
                        Padding(
                          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 24),
                              // Primary Action: Google Login
                              OutlinedButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : () => ref.read(authProvider.notifier).signInWithGoogle(),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(56),
                                  side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CustomPaint(
                                        painter: GoogleLogoPainter(),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      _getString('continue_with_google', lang),
                                      style: GoogleFonts.inter(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                      height: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Text(
                                      _getString('or_divider', lang).toUpperCase(),
                                      style: GoogleFonts.inter(
                                        color: theme.colorScheme.outline,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Form Fields
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Full Name (Only for Sign Up)
                                    if (_isSignUp) ...[
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(left: 4.0),
                                            child: Text(
                                              _getString('fullname_label', lang),
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          TextFormField(
                                            controller: _fullNameController,
                                            style: GoogleFonts.inter(
                                              color: theme.colorScheme.onSurface,
                                              fontSize: 14,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: _getString('fullname_hint', lang),
                                              hintStyle: GoogleFonts.inter(
                                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                                fontSize: 14,
                                              ),
                                              prefixIcon: Icon(
                                                Icons.person_outline_rounded,
                                                color: theme.colorScheme.outline,
                                              ),
                                              fillColor: theme.colorScheme.surfaceContainerLow,
                                              filled: true,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: primaryColor, width: 1.5),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            ),
                                            validator: (val) {
                                              if (val == null || val.trim().isEmpty) {
                                                return lang == AppLanguage.hi
                                                    ? 'कृपया अपना पूरा नाम दर्ज करें'
                                                    : 'Please enter your full name';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(left: 4.0),
                                            child: Text(
                                              _getString('mobile_label', lang),
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          TextFormField(
                                            controller: _mobileController,
                                            keyboardType: TextInputType.phone,
                                            style: GoogleFonts.inter(
                                              color: theme.colorScheme.onSurface,
                                              fontSize: 14,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: _getString('mobile_hint', lang),
                                              hintStyle: GoogleFonts.inter(
                                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                                fontSize: 14,
                                              ),
                                              prefixIcon: Icon(
                                                Icons.phone_outlined,
                                                color: theme.colorScheme.outline,
                                              ),
                                              fillColor: theme.colorScheme.surfaceContainerLow,
                                              filled: true,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: primaryColor, width: 1.5),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            ),
                                            validator: (val) {
                                              if (val == null || val.trim().isEmpty) {
                                                return lang == AppLanguage.hi
                                                    ? 'कृपया अपना मोबाइल नंबर दर्ज करें'
                                                    : 'Please enter your mobile number';
                                              }
                                              if (!RegExp(r'^[0-9]{10}$').hasMatch(val.trim())) {
                                                return lang == AppLanguage.hi
                                                    ? 'कृपया एक मान्य 10 अंकों का मोबाइल नंबर दर्ज करें'
                                                    : 'Please enter a valid 10-digit mobile number';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    // Email field
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4.0),
                                          child: Text(
                                            _getString('email_label', lang),
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        TextFormField(
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          style: GoogleFonts.inter(
                                            color: theme.colorScheme.onSurface,
                                            fontSize: 14,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: _getString('email_hint', lang),
                                            hintStyle: GoogleFonts.inter(
                                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                              fontSize: 14,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.mail_outline_rounded,
                                              color: theme.colorScheme.outline,
                                            ),
                                            fillColor: theme.colorScheme.surfaceContainerLow,
                                            filled: true,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: primaryColor, width: 1.5),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          ),
                                          validator: (val) {
                                            if (val == null || val.trim().isEmpty) {
                                              return lang == AppLanguage.hi
                                                  ? 'कृपया अपना ईमेल दर्ज करें'
                                                  : 'Please enter your email';
                                            }
                                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                                              return lang == AppLanguage.hi
                                                  ? 'कृपया एक मान्य ईमेल दर्ज करें'
                                                  : 'Please enter a valid email';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Password field
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(left: 4.0),
                                              child: Text(
                                                _getString('password_label', lang),
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                            if (!_isSignUp)
                                              TextButton(
                                                onPressed: () => _showForgotPasswordDialog(context),
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                child: Text(
                                                  _getString('forgot_password', lang),
                                                  style: GoogleFonts.inter(
                                                    color: secondaryColor,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 11,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          style: GoogleFonts.inter(
                                            color: theme.colorScheme.onSurface,
                                            fontSize: 14,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: _getString('password_hint', lang),
                                            hintStyle: GoogleFonts.inter(
                                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                              fontSize: 14,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.lock_outline_rounded,
                                              color: theme.colorScheme.outline,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                                color: theme.colorScheme.outline,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword = !_obscurePassword;
                                                });
                                              },
                                            ),
                                            fillColor: theme.colorScheme.surfaceContainerLow,
                                            filled: true,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: primaryColor, width: 1.5),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          ),
                                          validator: (val) {
                                            if (val == null || val.isEmpty) {
                                              return lang == AppLanguage.hi
                                                  ? 'कृपया पासवर्ड दर्ज करें'
                                                  : 'Please enter password';
                                            }
                                            if (val.length < 6) {
                                              return lang == AppLanguage.hi
                                                  ? 'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए'
                                                  : 'Password must be at least 6 characters';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),

                                    if (_isSignUp) ...[
                                      const SizedBox(height: 16),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: Checkbox(
                                              value: _agreeToTerms,
                                              activeColor: primaryColor,
                                              checkColor: Colors.white,
                                              onChanged: (val) {
                                                setState(() {
                                                  _agreeToTerms = val ?? false;
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                  height: 1.4,
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text: lang == AppLanguage.hi
                                                        ? 'खाता बनाकर, मैं रांदड़ परिवार समाज के '
                                                        : 'By creating an account, I agree to the ',
                                                  ),
                                                  WidgetSpan(
                                                    alignment: PlaceholderAlignment.baseline,
                                                    baseline: TextBaseline.alphabetic,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              lang == AppLanguage.hi
                                                                  ? 'सेवा की शर्तें जल्द ही उपलब्ध होंगी।'
                                                                  : 'Terms of Service will be available soon.',
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: Text(
                                                        lang == AppLanguage.hi ? 'सेवा की शर्तों' : 'Terms of Service',
                                                        style: GoogleFonts.inter(
                                                          color: secondaryColor,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 13,
                                                          decoration: TextDecoration.underline,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: lang == AppLanguage.hi ? ' और ' : ' and ',
                                                  ),
                                                  WidgetSpan(
                                                    alignment: PlaceholderAlignment.baseline,
                                                    baseline: TextBaseline.alphabetic,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              lang == AppLanguage.hi
                                                                  ? 'गोपनीयता नीति जल्द ही उपलब्ध होगी।'
                                                                  : 'Privacy Policy will be available soon.',
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: Text(
                                                        lang == AppLanguage.hi ? 'गोपनीयता नीति' : 'Privacy Policy',
                                                        style: GoogleFonts.inter(
                                                          color: secondaryColor,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 13,
                                                          decoration: TextDecoration.underline,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: lang == AppLanguage.hi ? ' से सहमत हूँ।' : ' of Akhil Bhartiya Rander Parivar.',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],

                                    const SizedBox(height: 24),

                                    // Login / Register Submit Button
                                    if (authState.isLoading)
                                      Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                        ),
                                      )
                                    else
                                      ElevatedButton(
                                        onPressed: _submitForm,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.white,
                                          elevation: 2,
                                          minimumSize: const Size.fromHeight(56),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _getString(_isSignUp ? 'register_btn' : 'login_btn', lang),
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.15,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),

                                    const SizedBox(height: 20),

                                    // Toggle Mode: Sign In / Sign Up
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _getString(_isSignUp ? 'switch_login_prompt' : 'switch_signup_prompt', lang),
                                          style: GoogleFonts.inter(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            fontSize: 14,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _isSignUp = !_isSignUp;
                                              _formKey.currentState?.reset();
                                              _fullNameController.clear();
                                              _emailController.clear();
                                              _passwordController.clear();
                                              _agreeToTerms = false;
                                            });
                                          },
                                          child: Text(
                                            _getString(_isSignUp ? 'switch_login_btn' : 'switch_signup_btn', lang),
                                            style: GoogleFonts.inter(
                                              color: primaryColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Error message
                                    if (authState.errorMessage != null) ...[
                                      const SizedBox(height: 20),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          authState.errorMessage!,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            color: theme.colorScheme.error,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Decorative Footer Elements (Heritage · Community · Progress)
                  const SizedBox(height: 32),
                  Text(
                    'HERITAGE · COMMUNITY · PROGRESS',
                    style: GoogleFonts.inter(
                      color: theme.colorScheme.outline,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.temple_hindu_outlined, color: theme.colorScheme.outlineVariant, size: 24),
                      const SizedBox(width: 32),
                      Icon(Icons.schema_outlined, color: theme.colorScheme.outlineVariant, size: 24),
                      const SizedBox(width: 32),
                      Icon(Icons.diversity_3_outlined, color: theme.colorScheme.outlineVariant, size: 24),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final lang = ref.read(languageStateProvider);
    final theme = Theme.of(context);
    final emailController = TextEditingController(text: _emailController.text.trim());
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    
    bool isOtpSent = false;
    bool isLoading = false;
    String? errorMessage;
    String? devOtpHint;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang == AppLanguage.hi ? 'पासवर्ड रीसेट करें' : 'Reset Password',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isOtpSent
                        ? (lang == AppLanguage.hi
                            ? 'अपने ईमेल में प्राप्त 6-अंकों का ओटीपी और नया पासवर्ड दर्ज करें।'
                            : 'Enter the 6-digit OTP code sent to your email and your new password.')
                        : (lang == AppLanguage.hi
                            ? 'ओटीपी प्राप्त करने के लिए अपना पंजीकृत ईमेल दर्ज करें।'
                            : 'Enter your registered email address to receive a password reset OTP code.'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (devOtpHint != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Dev OTP: $devOtpHint',
                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (!isOtpSent) ...[
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: lang == AppLanguage.hi ? 'ईमेल पता' : 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              final email = emailController.text.trim();
                              if (email.isEmpty) {
                                setModalState(() => errorMessage = lang == AppLanguage.hi ? 'ईमेल दर्ज करें' : 'Please enter email');
                                return;
                              }
                              setModalState(() {
                                isLoading = true;
                                errorMessage = null;
                              });
                              try {
                                final otp = await ref.read(authProvider.notifier).forgotPassword(email);
                                setModalState(() {
                                  isLoading = false;
                                  isOtpSent = true;
                                  devOtpHint = otp;
                                });
                              } catch (e) {
                                setModalState(() {
                                  isLoading = false;
                                  errorMessage = e.toString().replaceAll('Exception: ', '');
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(lang == AppLanguage.hi ? 'ओटीपी भेजें' : 'Send OTP'),
                    ),
                  ] else ...[
                    TextFormField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: lang == AppLanguage.hi ? '6-अंकों का ओटीपी' : '6-Digit OTP Code',
                        prefixIcon: const Icon(Icons.pin_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: lang == AppLanguage.hi ? 'नया पासवर्ड' : 'New Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              final email = emailController.text.trim();
                              final otp = otpController.text.trim();
                              final newPass = newPasswordController.text.trim();
                              if (otp.isEmpty || newPass.isEmpty) {
                                setModalState(() => errorMessage = lang == AppLanguage.hi ? 'सभी फ़ील्ड भरें' : 'Please fill all fields');
                                return;
                              }
                              setModalState(() {
                                isLoading = true;
                                errorMessage = null;
                              });
                               final messenger = ScaffoldMessenger.of(context);
                              try {
                                await ref.read(authProvider.notifier).resetPassword(email, otp, newPass);
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (mounted) {
                                  _emailController.text = email;
                                  _passwordController.text = newPass;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(lang == AppLanguage.hi ? 'पासवर्ड सफलतापूर्वक बदल दिया गया! लॉग इन करें।' : 'Password reset successful! You can now log in.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() {
                                  isLoading = false;
                                  errorMessage = e.toString().replaceAll('Exception: ', '');
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(lang == AppLanguage.hi ? 'पासवर्ड रीसेट करें' : 'Reset Password'),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── CUSTOM WEAVE/EMBLEM WIDGET ──────────────────────────────────────────────

class CommunityEmblem extends StatelessWidget {
  final double size;
  const CommunityEmblem({super.key, this.size = 140});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary; // Gilded Saffron
    final secondaryColor = theme.colorScheme.secondary; // Deep Maroon

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer base circle with drop shadow and deep maroon border
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF6F0), // Warm parchment inside
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: secondaryColor.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: secondaryColor,
                width: 3.5,
              ),
            ),
          ),
          // Inner decorative thin circle
          Container(
            width: size - 12,
            height: size - 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
          ),
          // Curved Top text: श्री गणेशाय नमः
          Positioned.fill(
            child: CustomPaint(
              painter: CurvedTextPainter(
                text: '|| श्री गणेशाय नमः ||',
                radius: (size / 2) - 15,
                isTop: true,
                textStyle: TextStyle(
                  color: secondaryColor,
                  fontSize: size * 0.075,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          // Curved Bottom text: महेशाय नमः
          Positioned.fill(
            child: CustomPaint(
              painter: CurvedTextPainter(
                text: '|| महेशाय नमः ||',
                radius: (size / 2) - 15,
                isTop: false,
                textStyle: TextStyle(
                  color: secondaryColor,
                  fontSize: size * 0.075,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          // Center Kalash Drawing
          Positioned(
            top: size * 0.28,
            child: SizedBox(
              width: size * 0.44,
              height: size * 0.44,
              child: CustomPaint(
                painter: KalashPainter(
                  color: primaryColor,
                  secondaryColor: secondaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CUSTOM PAINTERS ─────────────────────────────────────────────────────────

class CurvedTextPainter extends CustomPainter {
  final String text;
  final double radius;
  final TextStyle textStyle;
  final bool isTop;

  CurvedTextPainter({
    required this.text,
    required this.radius,
    required this.textStyle,
    required this.isTop,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Use characters to support Hindi conjunct letters correctly
    final charList = text.characters.toList();
    final totalChars = charList.length;

    // Angle coverage config
    final double sweepAngle = isTop ? 1.4 : 1.1;
    final double startAngle = isTop
        ? -pi / 2 - sweepAngle / 2
        : pi / 2 - sweepAngle / 2;

    final double angleStep = sweepAngle / (totalChars - 1);

    for (var i = 0; i < totalChars; i++) {
      final double charAngle = startAngle + i * angleStep;

      // Position along circumference
      final double x = cx + radius * cos(charAngle);
      final double y = cy + radius * sin(charAngle);

      canvas.save();
      canvas.translate(x, y);

      // Rotate text to align along curve tangent
      final double rotationAngle = isTop ? charAngle + pi / 2 : charAngle - pi / 2;
      canvas.rotate(rotationAngle);

      final textPainter = TextPainter(
        text: TextSpan(text: charList[i], style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CurvedTextPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.radius != radius ||
        oldDelegate.textStyle != textStyle ||
        oldDelegate.isTop != isTop;
  }
}

class KalashPainter extends CustomPainter {
  final Color color;
  final Color secondaryColor;

  KalashPainter({required this.color, required this.secondaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // 1. Bottom flat base for pot
    final baseRect = Rect.fromCenter(center: Offset(cx, cy + 24), width: size.width * 0.35, height: 4);
    canvas.drawRRect(RRect.fromRectAndRadius(baseRect, const Radius.circular(2)), paint);

    // 2. Pot (Kalash) main body
    final potPath = Path();
    potPath.moveTo(cx - size.width * 0.16, cy + 22);
    // Left belly curve to neck
    potPath.cubicTo(
      cx - size.width * 0.38, cy + 18,
      cx - size.width * 0.38, cy - 2,
      cx - size.width * 0.18, cy - 6,
    );
    // Connect to right side of neck
    potPath.lineTo(cx + size.width * 0.18, cy - 6);
    // Right belly curve to base
    potPath.cubicTo(
      cx + size.width * 0.38, cy - 2,
      cx + size.width * 0.38, cy + 18,
      cx + size.width * 0.16, cy + 22,
    );
    potPath.close();
    canvas.drawPath(potPath, paint);

    // 3. Pot flared neck rim
    final rimRect = Rect.fromCenter(center: Offset(cx, cy - 8), width: size.width * 0.44, height: 4);
    canvas.drawRRect(RRect.fromRectAndRadius(rimRect, const Radius.circular(2)), paint);

    // 4. Coconut on top (brownish gold teardrop shape)
    final cocoPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final cocoPath = Path();
    cocoPath.moveTo(cx - size.width * 0.14, cy - 10);
    cocoPath.cubicTo(
      cx - size.width * 0.2, cy - 18,
      cx - size.width * 0.12, cy - 32,
      cx, cy - 36, // Tip of coconut
    );
    cocoPath.cubicTo(
      cx + size.width * 0.12, cy - 32,
      cx + size.width * 0.2, cy - 18,
      cx + size.width * 0.14, cy - 10,
    );
    cocoPath.close();
    canvas.drawPath(cocoPath, cocoPaint);

    // 5. Mango Leaves (Green, sprouting left and right)
    final leafPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.fill;

    // Left Leaf
    final leftLeaf = Path();
    leftLeaf.moveTo(cx - size.width * 0.14, cy - 10);
    leftLeaf.quadraticBezierTo(cx - size.width * 0.34, cy - 16, cx - size.width * 0.35, cy - 6);
    leftLeaf.quadraticBezierTo(cx - size.width * 0.22, cy - 2, cx - size.width * 0.12, cy - 8);
    leftLeaf.close();
    canvas.drawPath(leftLeaf, leafPaint);

    // Right Leaf
    final rightLeaf = Path();
    rightLeaf.moveTo(cx + size.width * 0.14, cy - 10);
    rightLeaf.quadraticBezierTo(cx + size.width * 0.34, cy - 16, cx + size.width * 0.35, cy - 6);
    rightLeaf.quadraticBezierTo(cx + size.width * 0.22, cy - 2, cx + size.width * 0.12, cy - 8);
    rightLeaf.close();
    canvas.drawPath(rightLeaf, leafPaint);

    // 6. Traditional Red Swastika (卐) on the gold pot
    final swasPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final scx = cx;
    final scy = cy + 8;
    final double swSize = size.width * 0.08;

    // Center lines
    canvas.drawLine(Offset(scx - swSize, scy), Offset(scx + swSize, scy), swasPaint); // Horizontal
    canvas.drawLine(Offset(scx, scy - swSize), Offset(scx, scy + swSize), swasPaint); // Vertical

    // Swastika hooks
    canvas.drawLine(Offset(scx - swSize, scy), Offset(scx - swSize, scy + swSize * 0.8), swasPaint); // Bottom-left
    canvas.drawLine(Offset(scx + swSize, scy), Offset(scx + swSize, scy - swSize * 0.8), swasPaint); // Top-right
    canvas.drawLine(Offset(scx, scy - swSize), Offset(scx - swSize * 0.8, scy - swSize), swasPaint); // Top-left
    canvas.drawLine(Offset(scx, scy + swSize), Offset(scx + swSize * 0.8, scy + swSize), swasPaint); // Bottom-right
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MandalaWatermarkPainter extends CustomPainter {
  final Color color;

  MandalaWatermarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw watermark mandala at the bottom-right corner
    final brCenter = Offset(size.width * 1.0, size.height * 1.0);
    _drawMandala(canvas, brCenter, paint, size.width * 0.6);

    // Draw watermark mandala at the top-left corner
    final tlCenter = const Offset(0.0, 0.0);
    _drawMandala(canvas, tlCenter, paint, size.width * 0.5);
  }

  void _drawMandala(Canvas canvas, Offset center, Paint paint, double maxRadius) {
    // Standard concentric circles
    canvas.drawCircle(center, maxRadius * 0.2, paint);
    _drawDashedCircle(canvas, center, maxRadius * 0.4, paint, 6, 6);
    canvas.drawCircle(center, maxRadius * 0.6, paint);
    canvas.drawCircle(center, maxRadius * 0.8, paint);
    _drawDashedCircle(canvas, center, maxRadius, paint, 8, 8);

    // Outer spokes / petals
    final int spokeCount = 32;
    final double innerR = maxRadius * 0.8;
    final double outerR = maxRadius;
    for (var i = 0; i < spokeCount; i++) {
      final double angle = (2 * pi / spokeCount) * i;
      final start = Offset(
        center.dx + innerR * cos(angle),
        center.dy + innerR * sin(angle),
      );
      final end = Offset(
        center.dx + outerR * cos(angle),
        center.dy + outerR * sin(angle),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Paint paint, double dashLength, double gapLength) {
    final double circumference = 2 * pi * radius;
    final int totalSteps = (circumference / (dashLength + gapLength)).floor();
    final double angleStep = 2 * pi / totalSteps;

    for (var i = 0; i < totalSteps; i++) {
      final double startAngle = i * angleStep;
      final double sweep = dashLength / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GoogleLogoPainter extends CustomPainter {
  const GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // Blue Path
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final bluePath = Path()
      ..moveTo(22.56, 12.25)
      ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10.0)
      ..lineTo(12.0, 10.0)
      ..lineTo(12.0, 14.26)
      ..lineTo(17.92, 14.26)
      ..cubicTo(17.66, 15.63, 16.88, 16.79, 15.71, 17.57)
      ..lineTo(15.71, 20.34)
      ..lineTo(19.28, 20.34)
      ..cubicTo(21.36, 18.42, 22.56, 15.6, 22.56, 12.25)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Green Path
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final greenPath = Path()
      ..moveTo(12.0, 23.0)
      ..cubicTo(14.97, 23.0, 17.46, 22.02, 19.28, 20.34)
      ..lineTo(15.71, 17.57)
      ..cubicTo(14.73, 18.23, 13.48, 18.63, 12.0, 18.63)
      ..cubicTo(9.14, 18.63, 6.71, 16.7, 5.84, 14.1)
      ..lineTo(2.18, 14.1)
      ..lineTo(2.18, 16.94)
      ..cubicTo(3.99, 20.53, 7.7, 23.0, 12.0, 23.0)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Yellow Path
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final yellowPath = Path()
      ..moveTo(5.84, 14.09)
      ..cubicTo(5.62, 13.43, 5.49, 12.73, 5.49, 12.0)
      ..cubicTo(5.49, 11.27, 5.62, 10.57, 5.84, 9.91)
      ..lineTo(2.18, 9.91)
      ..lineTo(2.18, 7.07)
      ..cubicTo(1.43, 8.55, 1.0, 10.22, 1.0, 12.0)
      ..cubicTo(1.0, 13.78, 1.43, 15.45, 2.18, 16.93)
      ..lineTo(5.84, 14.09)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Red Path
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final redPath = Path()
      ..moveTo(12.0, 5.38)
      ..cubicTo(13.62, 5.38, 15.06, 5.94, 16.21, 7.02)
      ..lineTo(19.36, 3.87)
      ..cubicTo(17.45, 2.09, 14.97, 1.0, 12.0, 1.0)
      ..cubicTo(7.7, 1.0, 3.99, 3.47, 2.18, 6.23)
      ..lineTo(5.84, 9.07)
      ..cubicTo(6.71, 6.47, 9.3, 5.38, 12.0, 5.38)
      ..close();
    canvas.drawPath(redPath, redPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
