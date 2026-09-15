import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sungguard/l10n/app_localizations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

class PrivacyPolicyPage extends StatelessWidget {
  final VoidCallback? onBack;

  const PrivacyPolicyPage({super.key, this.onBack});

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
          l10n.profilePrivacy,
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
            // White Policy Card Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x060F172A),
                    blurRadius: 16.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header with Shield Icon
                  Row(
                    children: [
                      Container(
                        width: 48.0,
                        height: 48.0,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Color(0xFF1E40AF),
                          size: 24.0,
                        ),
                      ),
                      const SizedBox(width: 14.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.privacyTitle,
                            style: AppTypography.headingMedium.copyWith(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3.0),
                          Text(
                            l10n.privacyUpdated,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12.0,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20.0),

                  // Intro Paragraph
                  Text(
                    l10n.privacyIntro,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF475569),
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 22.0),

                  // Section 1
                  _buildSection(
                    l10n.privacyS1Title,
                    l10n.privacyS1Desc,
                  ),

                  const SizedBox(height: 18.0),

                  // Section 2
                  _buildSection(
                    l10n.privacyS2Title,
                    l10n.privacyS2Desc,
                  ),

                  const SizedBox(height: 18.0),

                  // Section 3
                  _buildSection(
                    l10n.privacyS3Title,
                    l10n.privacyS3Desc,
                  ),

                  const SizedBox(height: 18.0),

                  // Section 4
                  _buildSection(
                    l10n.privacyS4Title,
                    l10n.privacyS4Desc,
                  ),

                  const SizedBox(height: 18.0),

                  // Section 5
                  _buildSection(
                    l10n.privacyS5Title,
                    l10n.privacyS5Desc,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 90.0), // Spacing for bottom bar
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6.0),
        Text(
          content,
          style: const TextStyle(
            fontSize: 13.0,
            color: Color(0xFF64748B),
            height: 1.45,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
