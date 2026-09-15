import 'package:flutter/material.dart';
import 'package:sungguard/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_locale_controller.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class LanguageOption {
  final String code;
  final String title;
  final String nativeName;
  final String flag;

  const LanguageOption({
    required this.code,
    required this.title,
    required this.nativeName,
    required this.flag,
  });
}

const List<LanguageOption> kAppLanguages = [
  LanguageOption(code: 'en', title: 'English', nativeName: 'English', flag: '🇬🇧'),
  LanguageOption(code: 'hi', title: 'Hindi', nativeName: 'हिंदी', flag: '🇮🇳'),
  LanguageOption(code: 'gu', title: 'Gujarati', nativeName: 'ગુજરાતી', flag: '🇮🇳'),
  LanguageOption(code: 'mr', title: 'Marathi', nativeName: 'मराठी', flag: '🇮🇳'),
  LanguageOption(code: 'bn', title: 'Bengali', nativeName: 'বাংলা', flag: '🇮🇳'),
  LanguageOption(code: 'ta', title: 'Tamil', nativeName: 'தமிழ்', flag: '🇮🇳'),
  LanguageOption(code: 'te', title: 'Telugu', nativeName: 'తెలుగు', flag: '🇮🇳'),
  LanguageOption(code: 'kn', title: 'Kannada', nativeName: 'ಕನ್ನಡ', flag: '🇮🇳'),
  LanguageOption(code: 'ml', title: 'Malayalam', nativeName: 'മലയാളം', flag: '🇮🇳'),
  LanguageOption(code: 'pa', title: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ', flag: '🇮🇳'),
  LanguageOption(code: 'or', title: 'Odia', nativeName: 'ଓଡ଼ିଆ', flag: '🇮🇳'),
  LanguageOption(code: 'as', title: 'Assamese', nativeName: 'অসমীয়া', flag: '🇮🇳'),
  LanguageOption(code: 'ur', title: 'Urdu', nativeName: 'اردو', flag: '🇮🇳'),
  LanguageOption(code: 'kok', title: 'Konkani', nativeName: 'कोंकणी', flag: '🇮🇳'),
  LanguageOption(code: 'ne', title: 'Nepali', nativeName: 'नेपाली', flag: '🇮🇳'),
  LanguageOption(code: 'sa', title: 'Sanskrit', nativeName: 'संस्कृतम्', flag: '🇮🇳'),
  LanguageOption(code: 'ks', title: 'Kashmiri', nativeName: 'कॉशुर', flag: '🇮🇳'),
  LanguageOption(code: 'mai', title: 'Maithili', nativeName: 'मैथिली', flag: '🇮🇳'),
  LanguageOption(code: 'mni', title: 'Manipuri', nativeName: 'ꯃꯤꯇꯩꯂꯣꯟ', flag: '🇮🇳'),
  LanguageOption(code: 'brx', title: 'Bodo', nativeName: 'बर\'', flag: '🇮🇳'),
  LanguageOption(code: 'sat', title: 'Santali', nativeName: 'ᱥᱟᱱᱛᱟᱲᱤ', flag: '🇮🇳'),
  LanguageOption(code: 'sd', title: 'Sindhi', nativeName: 'سنڌي', flag: '🇮🇳'),
  LanguageOption(code: 'doi', title: 'Dogri', nativeName: 'डोगरी', flag: '🇮🇳'),
];

class LanguageSelectionPage extends StatelessWidget {
  final VoidCallback? onBack;

  const LanguageSelectionPage({super.key, this.onBack});

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLang = AppLocaleController.instance.value.languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20.0, color: Color(0xFF0F172A)),
          onPressed: () => _handleBack(context),
        ),
        titleSpacing: 0,
        title: Text(
          l10n.selectLanguage,
          style: AppTypography.headingLarge.copyWith(
            fontSize: 18.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8.0),
            Text(
              l10n.selectLanguage,
              style: AppTypography.headingMedium.copyWith(
                fontSize: 18.0,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              l10n.selectLanguageSubtitle,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20.0),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: kAppLanguages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10.0),
              itemBuilder: (context, index) {
                final lang = kAppLanguages[index];
                final isSelected = currentLang == lang.code;

                return _buildLanguageCard(
                  context: context,
                  flag: lang.flag,
                  title: '${lang.nativeName} (${lang.title})',
                  subtitle: l10n.selectLanguageItemSubtitle(lang.title),
                  langCode: lang.code,
                  isSelected: isSelected,
                  onTap: () {
                    AppLocaleController.instance.changeLocale(lang.code);
                  },
                );
              },
            ),

            const SizedBox(height: 24.0),

            // Information Box
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 38.0,
                    height: 38.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: const Icon(
                      Icons.translate_rounded,
                      color: Color(0xFF1D4ED8),
                      size: 20.0,
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Text(
                      l10n.switchLanguageNotice,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF1E40AF),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40.0),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required BuildContext context,
    required String flag,
    required String title,
    required String subtitle,
    required String langCode,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x10059669),
                    blurRadius: 10.0,
                    offset: Offset(0, 3),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x060F172A),
                    blurRadius: 8.0,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            // Flag Icon Container
            Container(
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: isSelected ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                flag,
                style: const TextStyle(fontSize: 22.0),
              ),
            ),
            const SizedBox(width: 14.0),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? const Color(0xFF059669) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Selection Checkmark Radio
            Container(
              width: 24.0,
              height: 24.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF059669) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                  width: isSelected ? 0 : 2.0,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 15.0,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
