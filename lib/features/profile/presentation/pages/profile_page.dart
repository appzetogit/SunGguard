import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sungguard/l10n/app_localizations.dart';

import '../../../../core/localization/app_locale_controller.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ProfilePage extends StatelessWidget {
  final Function(String route)? onNavigate;

  const ProfilePage({super.key, this.onNavigate});

  void _nav(BuildContext context, String route) {
    if (onNavigate != null) {
      onNavigate!(route);
    } else {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        final name = user?.name.isNotEmpty == true
            ? user!.name
            : (state.name.isNotEmpty ? state.name : 'Customer');
        final rawPhone = user?.phone.isNotEmpty == true
            ? user!.phone
            : (state.phone.isNotEmpty ? state.phone : '');
        final cleanPhone = rawPhone.replaceAll('+91', '').trim();
        final formattedPhone = cleanPhone.isNotEmpty ? '+91 $cleanPhone' : '';

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8FAFC),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18.0, color: Color(0xFF0F172A)),
              onPressed: () {
                if (onNavigate != null) {
                  onNavigate!('/');
                } else if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
            centerTitle: false,
            title: Text(
              l10n.profileTitle,
              style: AppTypography.headingLarge.copyWith(
                fontSize: 20.0,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16.0),
                width: 40.0,
                height: 40.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x060F172A),
                      blurRadius: 6.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.notifications_none_rounded, size: 20.0, color: Color(0xFF0F172A)),
                  onPressed: () => _nav(context, '/notifications'),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6.0),

                // 1. Top User Identity Card
                Container(
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
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Avatar Icon Box
                      Container(
                        width: 56.0,
                        height: 56.0,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFF0F172A),
                          size: 28.0,
                        ),
                      ),
                      const SizedBox(width: 14.0),

                      // User Name & Phone
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: AppTypography.headingMedium.copyWith(
                                fontSize: 18.0,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 5.0),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Text(
                                    'INDIA',
                                    style: AppTypography.monoLabel.copyWith(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF64748B),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  formattedPhone,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Edit Button
                      Container(
                        width: 42.0,
                        height: 42.0,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.edit_outlined, size: 20.0, color: Color(0xFF64748B)),
                          onPressed: () => _nav(context, '/profile/edit'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // 2. Personal Account Card (Header INSIDE card)
                Container(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header inside card
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 12.0),
                        child: Text(
                          l10n.profileTitle.toUpperCase(),
                          style: AppTypography.monoLabel.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const Divider(color: Color(0xFFF1F5F9), height: 1.0),

                      // Item 1: Parcel History
                      _buildMenuItem(
                        icon: Icons.history_rounded,
                        iconColor: const Color(0xFF0284C7),
                        iconBg: const Color(0xFFE0F2FE),
                        title: l10n.historyTitle,
                        subtitle: l10n.navWaybills,
                        onTap: () => _nav(context, '/profile/parcel-history'),
                      ),
                      const Divider(color: Color(0xFFF1F5F9), height: 1.0),

                      // Item 2: Wallet
                      _buildMenuItem(
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: const Color(0xFF10B981),
                        iconBg: const Color(0xFFDCFCE7),
                        title: l10n.profileWallet,
                        subtitle: l10n.walletBalance,
                        onTap: () => _nav(context, '/wallet'),
                      ),
                      const Divider(color: Color(0xFFF1F5F9), height: 1.0),

                      // Item 3: Saved Addresses
                      _buildMenuItem(
                        icon: Icons.location_on_outlined,
                        iconColor: const Color(0xFF0F172A),
                        iconBg: const Color(0xFFE0F2FE),
                        title: l10n.profileSavedAddresses,
                        subtitle: l10n.addressesTitle,
                        onTap: () => _nav(context, '/addresses'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // 3. Help & Settings Card (Header INSIDE card)
                Container(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header inside card
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 12.0),
                        child: Text(
                          l10n.profileSupport.toUpperCase(),
                          style: AppTypography.monoLabel.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const Divider(color: Color(0xFFF1F5F9), height: 1.0),

                      // Language Switcher Tile
                      _buildSimpleMenuItem(
                        icon: Icons.translate_rounded,
                        iconColor: const Color(0xFF059669),
                        iconBg: const Color(0xFFECFDF5),
                        title: '${l10n.changeLanguage} (${AppLocaleController.instance.currentLanguageNativeName})',
                        onTap: () => _nav(context, '/language'),
                      ),
                      const Divider(color: Color(0xFFF1F5F9), height: 1.0),

                      // Push channel toggles — GET/PATCH /push/preferences.
                      _buildSimpleMenuItem(
                        icon: Icons.notifications_active_outlined,
                        iconColor: const Color(0xFFEA580C),
                        iconBg: const Color(0xFFFFF7ED),
                        title: 'Notification settings',
                        onTap: () => _nav(context, '/notifications/settings'),
                      ),
                      const Divider(color: Color(0xFFF1F5F9), height: 1.0),

                      _buildSimpleMenuItem(
                        icon: Icons.help_outline_rounded,
                        iconColor: const Color(0xFF2563EB),
                        iconBg: const Color(0xFFEFF6FF),
                        title: l10n.profileSupport,
                        onTap: () => _nav(context, '/support'),
                      ),
                      const Divider(color: Color(0xFFF1F5F9), height: 1.0),
                      _buildSimpleMenuItem(
                        icon: Icons.warning_amber_rounded,
                        iconColor: const Color(0xFFD97706),
                        iconBg: const Color(0xFFFEF3C7),
                        title: l10n.supportRaiseTicket,
                        onTap: () => _nav(context, '/support?complaint=1'),
                      ),
                      const Divider(color: Color(0xFFF1F5F9), height: 1.0),
                      _buildSimpleMenuItem(
                        icon: Icons.shield_outlined,
                        iconColor: const Color(0xFF9333EA),
                        iconBg: const Color(0xFFF3E8FF),
                        title: l10n.profilePrivacy,
                        onTap: () => _nav(context, '/privacy'),
                      ),
                      const Divider(color: Color(0xFFF1F5F9), height: 1.0),
                      _buildSimpleMenuItem(
                        icon: Icons.info_outline_rounded,
                        iconColor: const Color(0xFF0D9488),
                        iconBg: const Color(0xFFCCFBF1),
                        title: l10n.profileAbout,
                        onTap: () => _nav(context, '/about'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // 4. Sign Out Button
                SizedBox(
                  width: double.infinity,
                  height: 50.0,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      context.read<AuthBloc>().add(AuthLogoutRequested());
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout, size: 18.0, color: Color(0xFF0F172A)),
                        const SizedBox(width: 8.0),
                        Text(
                          l10n.profileLogout,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18.0),

                // 5. Version Info
                Center(
                  child: Text(
                    'Version 2.4.0 - SunGguard',
                    style: AppTypography.monoLabel.copyWith(
                      fontSize: 11.5,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 90.0), // Floating bottom bar offset
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14.0),
              ),
              child: Icon(icon, color: iconColor, size: 24.0),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20.0),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14.0),
              ),
              child: Icon(icon, color: iconColor, size: 24.0),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20.0),
          ],
        ),
      ),
    );
  }
}
