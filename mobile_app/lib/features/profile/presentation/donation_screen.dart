import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_translations.dart';

class DonationScreen extends ConsumerWidget {
  const DonationScreen({super.key});

  // Official Bank Details of Akhil Bhartiya (Maheshwari) Rander Pariwar
  static const String beneficiaryName =
      'SHRI AKHIL BHARTIYA (MAHESHWARI) RANDER PARIWAR';
  static const String accountNumber = '61183216802';
  static const String ifscCode = 'SBIN0031113';
  static const String bankName = 'STATE BANK OF INDIA';
  static const String branchName = 'Jai Shiv Chowk, Makrana (Raj.)';
  static const String accountType = 'Savings Bank (S/B)';
  static const String supportEmail = 'randerparivaar@gmail.com';

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text('$label copied to clipboard!')),
          ],
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyAllDetails(BuildContext context) {
    const formatted = '''श्री अखिल भारतीय (माहेश्वरी) रांदड़ परिवार
SHRI AKHIL BHARTIYA (MAHESHWARI) RANDER PARIWAR

Bank Account Details for Donation / सहयोग बैंक विवरण:
─────────────────────────────────────
• Beneficiary Name / खाता धारक: $beneficiaryName
• Bank / बैंक: $bankName
• Account No / खाता संख्या: $accountNumber
• IFSC Code: $ifscCode
• Account Type / खाता प्रकार: $accountType
• Branch / शाखा: $branchName
─────────────────────────────────────
कृपया सहयोग राशि भेजने के उपरांत स्क्रीनशॉट अवश्य साझा करें ताकि आधिकारिक रसीद जारी की जा सके।
Email: $supportEmail''';

    _copyToClipboard(context, formatted, 'All Bank Details');
  }

  void _shareDetails(bool isHindi) {
    final shareText = isHindi
        ? '''🙏 श्री अखिल भारतीय (माहेश्वरी) रांदड़ परिवार 🙏
समाज विकास, शिक्षा एवं चिकित्सा सहयोग हेतु बैंक विवरण:

• खाता धारक: $beneficiaryName
• बैंक: $bankName
• खाता संख्या: $accountNumber
• IFSC कोड: $ifscCode
• खाता प्रकार: $accountType
• शाखा: $branchName

कृपया ट्रांसफर के बाद स्क्रीनशॉट भेजें ताकि आधिकारिक रसीद प्रदान की जा सके।
ईमेल: $supportEmail'''
        : '''🙏 Shri Akhil Bhartiya (Maheshwari) Rander Pariwar 🙏
Bank Account Details for Donation & Contributions:

• Beneficiary Name: $beneficiaryName
• Bank: $bankName
• Account Number: $accountNumber
• IFSC Code: $ifscCode
• Account Type: $accountType
• Branch: $branchName

Please share the transaction screenshot after transferring to receive your official receipt.
Email: $supportEmail''';

    SharePlus.instance.share(
      ShareParams(
        text: shareText,
        subject: isHindi
            ? 'रांदड़ परिवार समाज सहयोग बैंक विवरण'
            : 'ABRP Donation Bank Account Details',
      ),
    );
  }

  Future<void> _sendEmail() async {
    final mailUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {
        'subject': 'ABRP Donation Receipt / सहयोग राशि रसीद',
        'body':
            'Namaste,\n\nI have contributed to Shri Akhil Bhartiya (Maheshwari) Rander Pariwar.\n\nDonor Name:\nFather/Husband Name:\nCity/Village:\nAmount:\nUTR/Transaction ID:\nDate:\n\n(Please find attached transaction screenshot)',
      },
    );
    if (await canLaunchUrl(mailUri)) {
      await launchUrl(mailUri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageStateProvider);
    final isHindi = lang == AppLanguage.hi;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          isHindi ? 'सहयोग एवं दान राशि' : 'Donation Details',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 19,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: isHindi ? 'साझा करें' : 'Share',
            onPressed: () => _shareDetails(isHindi),
          ),
          TextButton(
            onPressed: () {
              final newLang =
                  lang == AppLanguage.en ? AppLanguage.hi : AppLanguage.en;
              ref.read(languageStateProvider.notifier).setLanguage(newLang);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.primary, width: 1.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isHindi ? 'English' : 'हिंदी',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // ─── Header Organization Card ───────────────────────────
          _buildOrganizationHeader(context, isHindi),
          const SizedBox(height: 16),

          // ─── Bank Account Details Card ───────────────────────────
          _buildBankDetailsCard(context, isHindi),
          const SizedBox(height: 16),

          // ─── Quick Action Buttons ────────────────────────────────
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _copyAllDetails(context),
                  icon: const Icon(Icons.copy_all_rounded, size: 20),
                  label: Text(
                    isHindi ? 'समस्त विवरण कॉपी करें' : 'Copy All Details',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareDetails(isHindi),
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: Text(
                    isHindi ? 'शेयर करें' : 'Share',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: colorScheme.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Receipt / Acknowledgment Guide ─────────────────────
          _buildReceiptGuideCard(context, isHindi),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 1. Organization Header
  // ─────────────────────────────────────────────────────────────
  Widget _buildOrganizationHeader(BuildContext context, bool isHindi) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.volunteer_activism_rounded,
            size: 38,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            isHindi
                ? 'श्री अखिल भारतीय (माहेश्वरी) रांदड़ परिवार'
                : 'Shri Akhil Bhartiya (Maheshwari) Rander Pariwar',
            style: GoogleFonts.outfit(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: colorScheme.onPrimaryContainer,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            isHindi
                ? 'समाज विकास, शिक्षा एवं चिकित्सा कल्याण सहयोग हेतु'
                : 'For Community Welfare, Education & Medical Care Support',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2. Bank Account Details Card
  // ─────────────────────────────────────────────────────────────
  Widget _buildBankDetailsCard(BuildContext context, bool isHindi) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bank Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bankName,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        isHindi
                            ? 'आधिकारिक बचत खाता (NEFT / RTGS / IMPS)'
                            : 'Official Savings Account (NEFT/RTGS/IMPS)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.blue.shade100,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Holder Name
                _buildInfoTile(
                  context,
                  label: isHindi ? 'खाता धारक (Beneficiary)' : 'Beneficiary Name',
                  value: beneficiaryName,
                  isBold: true,
                  onCopy: () => _copyToClipboard(
                    context,
                    beneficiaryName,
                    isHindi ? 'खाता धारक' : 'Beneficiary Name',
                  ),
                ),
                const Divider(height: 20),

                // Account Number (Highlighted)
                _buildHighlightedTile(
                  context,
                  label: isHindi ? 'खाता संख्या (A/C No.)' : 'Account Number',
                  value: accountNumber,
                  icon: Icons.tag,
                  onCopy: () => _copyToClipboard(
                    context,
                    accountNumber,
                    isHindi ? 'खाता संख्या' : 'Account Number',
                  ),
                ),
                const Divider(height: 20),

                // IFSC Code (Highlighted)
                _buildHighlightedTile(
                  context,
                  label: isHindi ? 'आईएफएससी कोड (IFSC)' : 'IFSC Code',
                  value: ifscCode,
                  icon: Icons.qr_code_2_rounded,
                  onCopy: () => _copyToClipboard(
                    context,
                    ifscCode,
                    'IFSC Code',
                  ),
                ),
                const Divider(height: 20),

                // Account Type & Branch
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHindi ? 'खाता प्रकार' : 'Account Type',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            accountType,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHindi ? 'शाखा (Branch)' : 'Branch',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            branchName,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required String label,
    required String value,
    bool isBold = false,
    required VoidCallback onCopy,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.copy_rounded,
            size: 19,
            color: colorScheme.primary,
          ),
          tooltip: 'Copy',
          onPressed: onCopy,
        ),
      ],
    );
  }

  Widget _buildHighlightedTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onCopy,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onCopy,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.copy_rounded, size: 14, color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Copy',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 3. Receipt Acknowledgment & Process Guide
  // ─────────────────────────────────────────────────────────────
  Widget _buildReceiptGuideCard(BuildContext context, bool isHindi) {
    final colorScheme = Theme.of(context).colorScheme;

    final steps = [
      isHindi
          ? 'बैंक ट्रांसफर (NEFT / RTGS / IMPS / Net Banking) द्वारा राशि प्रेषित करें।'
          : 'Transfer the contribution via Net Banking (NEFT/RTGS/IMPS).',
      isHindi
          ? 'सफल ट्रांजेक्शन का स्क्रीनशॉट अथवा UTR नंबर सुरक्षित रखें।'
          : 'Save the transaction screenshot or UTR / Reference Number.',
      isHindi
          ? 'आधिकारिक रसीद प्राप्त करने हेतु स्क्रीनशॉट, अपना पूरा नाम, पिता/पति का नाम एवं शहर/ग्राम समिति को ईमेल करें।'
          : 'Share screenshot along with your Full Name, Father/Husband Name & City to receive the official receipt.',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                isHindi ? 'रसीद एवं पावती प्रक्रिया' : 'Official Receipt Process',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        height: 1.35,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _sendEmail,
            icon: const Icon(Icons.email_outlined, size: 18),
            label: Text(
              isHindi
                  ? 'ईमेल द्वारा रसीद का अनुरोध करें'
                  : 'Request Receipt via Email',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
