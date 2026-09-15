import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sungguard/l10n/app_localizations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

class AboutUsPage extends StatelessWidget {
  final VoidCallback? onBack;

  const AboutUsPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20.0, color: Color(0xFF0F172A)),
          onPressed: () {
            if (onBack != null) {
              onBack!();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        titleSpacing: 0,
        title: Text(
          l10n.profileAbout,
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
          children: [
            // Card 1: Brand Hero Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x060F172A),
                    blurRadius: 14.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
              child: Column(
                children: [
                  Container(
                    width: 48.0,
                    height: 48.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFF0F172A),
                      size: 24.0,
                    ),
                  ),
                  const SizedBox(height: 14.0),
                  Text(
                    'SunGguard',
                    style: AppTypography.headingMedium.copyWith(
                      fontSize: 19.0,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    l10n.aboutTagline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.0,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Card 2: Our Mission
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x060F172A),
                    blurRadius: 14.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38.0,
                        height: 38.0,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: const Icon(
                          Icons.local_shipping_outlined,
                          color: Color(0xFF0F172A),
                          size: 20.0,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Text(
                        l10n.aboutMissionTitle,
                        style: AppTypography.headingSmall.copyWith(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14.0),
                  Text(
                    l10n.aboutMissionDesc,
                    style: const TextStyle(
                      fontSize: 13.0,
                      color: Color(0xFF475569),
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Card 3: Our Values
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x060F172A),
                    blurRadius: 14.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38.0,
                        height: 38.0,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          color: Color(0xFF0F172A),
                          size: 20.0,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Text(
                        l10n.aboutValuesTitle,
                        style: AppTypography.headingSmall.copyWith(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14.0),

                  _buildValueBullet(
                    l10n.aboutVal1Title,
                    l10n.aboutVal1Desc,
                  ),
                  const SizedBox(height: 10.0),
                  _buildValueBullet(
                    l10n.aboutVal2Title,
                    l10n.aboutVal2Desc,
                  ),
                  const SizedBox(height: 10.0),
                  _buildValueBullet(
                    l10n.aboutVal3Title,
                    l10n.aboutVal3Desc,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24.0),

            // Footer
            Text(
              l10n.aboutCopyright,
              style: const TextStyle(
                fontSize: 12.0,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 100.0), // Spacing for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildValueBullet(String boldPrefix, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6.0, right: 8.0),
          child: Container(
            width: 5.0,
            height: 5.0,
            decoration: const BoxDecoration(
              color: Color(0xFFCBD5E1),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13.0,
                color: Color(0xFF475569),
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: boldPrefix,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
