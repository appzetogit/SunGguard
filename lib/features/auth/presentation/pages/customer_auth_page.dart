import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_auth/smart_auth.dart';
import 'package:sungguard/l10n/app_localizations.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/accepted_stamp.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/depot_ground.dart';
// import '../../../../core/widgets/ink_barcode.dart';
// import '../../../../core/widgets/perforation_line.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/wrong_mode_dialog.dart';

class TenDigitPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 5) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    int cursorPosition = formatted.length;
    if (newValue.selection.baseOffset < newValue.text.length) {
      final digitsBeforeCursor = newValue.text
          .substring(
            0,
            newValue.selection.baseOffset.clamp(0, newValue.text.length),
          )
          .replaceAll(RegExp(r'\D'), '')
          .length;
      if (digitsBeforeCursor <= 5) {
        cursorPosition = digitsBeforeCursor;
      } else {
        cursorPosition = digitsBeforeCursor + 1;
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: cursorPosition.clamp(0, formatted.length),
      ),
    );
  }
}

class CustomerAuthPage extends StatefulWidget {
  const CustomerAuthPage({super.key});

  @override
  State<CustomerAuthPage> createState() => _CustomerAuthPageState();
}

class _CustomerAuthPageState extends State<CustomerAuthPage> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  int _resendSeconds = 0;
  Timer? _timer;
  bool _showOtpSentToast = false;

  String get _cleanPhone {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '').trim();
    if (digits.startsWith('91') && digits.length > 10) {
      return digits.substring(2);
    }
    return digits;
  }

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
    _nameController.addListener(() => setState(() {}));
    _otpController.addListener(() => setState(() {}));
    _requestPhoneNumberHint();
  }

  void _requestPhoneNumberHint() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      bool isLoggedIn = false;
      try {
        isLoggedIn = await sl<SecureStorageService>().getIsLoggedIn();
      } catch (_) {
        isLoggedIn = false;
      }

      if (isLoggedIn || _phoneController.text.trim().isNotEmpty) {
        return;
      }

      try {
        final smartAuth = SmartAuth.instance;
        final res = await smartAuth.requestPhoneNumberHint();

        if (!mounted) return;
        bool currentIsLoggedIn = false;
        try {
          currentIsLoggedIn = await sl<SecureStorageService>().getIsLoggedIn();
        } catch (_) {
          currentIsLoggedIn = false;
        }

        if (currentIsLoggedIn ||
            res.data == null ||
            res.data!.isEmpty) {
          return;
        }

        final autoPhone = res.data!;
        final digits = autoPhone.replaceAll(RegExp(r'\D'), '');
        final clean10Digits = digits.length >= 10
            ? digits.substring(digits.length - 10)
            : digits;

        if (clean10Digits.length == 10) {
          final formattedValue = TenDigitPhoneInputFormatter().formatEditUpdate(
            TextEditingValue.empty,
            TextEditingValue(
              text: clean10Digits,
              selection: TextSelection.collapsed(offset: clean10Digits.length),
            ),
          );
          setState(() {
            _phoneController.value = formattedValue;
          });
        }
      } catch (_) {
        // Gracefully handle user cancellation or non-Android environment
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _resendSeconds = 30;
      _showOtpSentToast = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  double _calculateProgress(AuthState state) {
    if (state.isSuccessAccepted) return 1.0;
    final phone = _cleanPhone.isNotEmpty
        ? _cleanPhone
        : state.phone.replaceAll(RegExp(r'\D'), '');
    final phoneRatio = (phone.length / 10).clamp(0.0, 1.0);
    if (state.step == AuthStep.code) {
      final codeRatio = (_otpController.text.length / 4).clamp(0.0, 1.0);
      return 0.62 + (0.38 * codeRatio);
    }
    if (state.isLogin) {
      return 0.62 * phoneRatio;
    } else {
      final name = _nameController.text.isNotEmpty
          ? _nameController.text
          : state.name;
      final nameFilled = name.trim().isNotEmpty ? 0.35 : 0.0;
      return 0.62 * (nameFilled + (phoneRatio * 0.65));
    }
  }

  String _formatPhone(String raw) {
    final clean = raw.replaceAll(RegExp(r'\D'), '');
    if (clean.length > 5) {
      return '${clean.substring(0, 5)} ${clean.substring(5)}';
    }
    return clean;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.wrongMode != current.wrongMode ||
          previous.otpSent != current.otpSent,
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppSnackBar.showError(context, AppLocalizations.of(context)!.error);
        }

        if (state.wrongMode != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => WrongModeDialog(
              targetMode: state.wrongMode!,
              phone: state.phone.isNotEmpty ? state.phone : _cleanPhone,
              onSwitch: () {
                Navigator.of(ctx).pop();
                context.read<AuthBloc>().add(
                  AuthModeSwitched(state.wrongMode!),
                );
              },
              onCancel: () {
                Navigator.of(ctx).pop();
                _phoneController.clear();
              },
            ),
          );
        }

        if (state.otpSent && state.step == AuthStep.code) {
          _startResendTimer();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _otpFocusNode.requestFocus();
          });
        }
      },
      builder: (context, state) {
        final progress = _calculateProgress(state);
        final currentPhone = _cleanPhone.isNotEmpty
            ? _cleanPhone
            : state.phone.replaceAll(RegExp(r'\D'), '');

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: DepotGround(
            child: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A0F172A),
                                blurRadius: 32.0,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Carrier Dark Consignment Header
                              _buildConsignmentHeader(
                                state,
                                currentPhone,
                                progress,
                              ),

                              // 2. Tear Notches at Divider
                              _buildTearDivider(),

                              // 3. Body Form Content
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (state.step == AuthStep.identity) ...[
                                      // Tab Mode Switcher
                                      _buildModeSwitcher(state),

                                      const SizedBox(height: AppSpacing.xl),

                                      // Heading & Subtitle
                                      Builder(
                                        builder: (context) {
                                          final l10n = AppLocalizations.of(
                                            context,
                                          )!;
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                state.isLogin
                                                    ? l10n.authWelcomeBack
                                                    : l10n.authRegisterTitle,
                                                style: AppTypography
                                                    .headingLarge
                                                    .copyWith(
                                                      fontSize: 22.0,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: AppColors.ink,
                                                    ),
                                              ),
                                              const SizedBox(height: 4.0),
                                              Text(
                                                state.isLogin
                                                    ? l10n.authLoginSubtitle
                                                    : l10n.authRegisterSubtitle,
                                                style: AppTypography.bodyRegular
                                                    .copyWith(
                                                      fontSize: 13.0,
                                                      color: const Color(
                                                        0xFF64748B,
                                                      ),
                                                    ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),

                                      const SizedBox(height: AppSpacing.lg),

                                      if (!state.isLogin) ...[
                                        Builder(
                                          builder: (context) =>
                                              _buildMonoCaption(
                                                AppLocalizations.of(context)!
                                                    .fullName
                                                    .toUpperCase(),
                                              ),
                                        ),
                                        const SizedBox(height: 6.0),
                                        _buildNameInput(),
                                        const SizedBox(height: AppSpacing.md),
                                      ],

                                      Builder(
                                        builder: (context) => _buildMonoCaption(
                                          AppLocalizations.of(context)!
                                              .phoneNumber
                                              .toUpperCase(),
                                        ),
                                      ),
                                      const SizedBox(height: 6.0),
                                      _buildPhoneInput(),

                                      const SizedBox(height: 6.0),
                                      Builder(
                                        builder: (context) {
                                          return Text(
                                            AppLocalizations.of(context)!
                                                .authEnterMobile,
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                                  fontSize: 11.5,
                                                  color: const Color(
                                                    0xFF64748B,
                                                  ),
                                                ),
                                          );
                                        },
                                      ),

                                      const SizedBox(height: AppSpacing.xl),

                                      // Primary Action Button
                                      Builder(
                                        builder: (context) {
                                          final l10n = AppLocalizations.of(
                                            context,
                                          )!;
                                          return _buildPrimarySubmitButton(
                                            label: '${l10n.authSendOtp}  →',
                                            isLoading: state.isLoading,
                                            isEnabled:
                                                currentPhone.length == 10 &&
                                                (state.isLogin ||
                                                    _nameController.text
                                                        .trim()
                                                        .isNotEmpty),
                                            onPressed: () {
                                              final phone =
                                                  _cleanPhone.isNotEmpty
                                                  ? '+91 $_cleanPhone'
                                                  : state.phone;
                                              final name =
                                                  _nameController.text
                                                      .trim()
                                                      .isNotEmpty
                                                  ? _nameController.text.trim()
                                                  : state.name;

                                              context.read<AuthBloc>().add(
                                                AuthSendOtpRequested(
                                                  name: name,
                                                  phone: phone,
                                                  isLogin: state.isLogin,
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),

                                      const SizedBox(height: AppSpacing.lg),

                                      // Legal Terms
                                      _buildTermsNotice(),
                                    ] else ...[
                                      // Step 2: Verification Code
                                      _buildOtpStepHeader(state, currentPhone),

                                      const SizedBox(height: AppSpacing.lg),

                                      Builder(
                                        builder: (context) => _buildMonoCaption(
                                          AppLocalizations.of(context)!
                                              .authEnterOtp
                                              .toUpperCase(),
                                        ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      _build4DigitOtpBoxes(),

                                      const SizedBox(height: AppSpacing.xl),

                                      if (state.isSuccessAccepted)
                                        Center(
                                          child: Builder(
                                            builder: (context) {
                                              return AcceptedStamp(
                                                label: AppLocalizations.of(
                                                  context,
                                                )!.success.toUpperCase(),
                                              );
                                            },
                                          ),
                                        )
                                      else ...[
                                        Builder(
                                          builder: (context) {
                                            final l10n = AppLocalizations.of(
                                              context,
                                            )!;
                                            return _buildPrimarySubmitButton(
                                              label: '${l10n.authVerifyOtp}  →',
                                              isLoading: state.isLoading,
                                              isEnabled:
                                                  _otpController.text.length ==
                                                  4,
                                              onPressed: () {
                                                final phone =
                                                    _cleanPhone.isNotEmpty
                                                    ? '+91 $_cleanPhone'
                                                    : state.phone;
                                                final name =
                                                    _nameController.text
                                                        .trim()
                                                        .isNotEmpty
                                                    ? _nameController.text
                                                          .trim()
                                                    : state.name;

                                                context.read<AuthBloc>().add(
                                                  AuthVerifyOtpRequested(
                                                    name: name,
                                                    phone: phone,
                                                    otp: _otpController.text
                                                        .trim(),
                                                    isLogin: state.isLogin,
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        Center(
                                          child: GestureDetector(
                                            onTap: _resendSeconds > 0
                                                ? null
                                                : () {
                                                    final phone =
                                                        _cleanPhone.isNotEmpty
                                                        ? '+91 $_cleanPhone'
                                                        : state.phone;
                                                    final name =
                                                        _nameController.text
                                                            .trim()
                                                            .isNotEmpty
                                                        ? _nameController.text
                                                              .trim()
                                                        : state.name;

                                                    context
                                                        .read<AuthBloc>()
                                                        .add(
                                                          AuthSendOtpRequested(
                                                            name: name,
                                                            phone: phone,
                                                            isLogin:
                                                                state.isLogin,
                                                          ),
                                                        );
                                                  },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4.0,
                                                  ),
                                              child: Builder(
                                                builder: (context) {
                                                  final l10n =
                                                      AppLocalizations.of(
                                                        context,
                                                      )!;
                                                  return Text(
                                                    _resendSeconds > 0
                                                        ? '${l10n.authResendOtp} (${_resendSeconds}s)'
                                                        : l10n.authResendOtp
                                                              .toUpperCase(),
                                                    style: AppTypography
                                                        .monoLabel
                                                        .copyWith(
                                                          fontSize: 10.5,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              _resendSeconds > 0
                                                              ? const Color(
                                                                  0xFF94A3B8,
                                                                )
                                                              : AppColors.navy,
                                                          letterSpacing: 1.0,
                                                        ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],

                                    const SizedBox(height: AppSpacing.xl),

                                    // // Perforation Line
                                    // const PerforationLine(
                                    //   color: Color(0xFFE2E8F0),
                                    //   dashWidth: 4.0,
                                    //   dashGap: 4.0,
                                    // ),
                                    // const SizedBox(height: AppSpacing.md),

                                    // Barcode & Machine-readable footer
                                    /*
                                    InkBarcode(
                                      seed: currentPhone.isNotEmpty
                                          ? currentPhone
                                          : 'SUNGGUARD',
                                      ratio: progress,
                                      color: AppColors.ink,
                                      height: 26.0,
                                    ),
                                    */
                                    // const SizedBox(height: AppSpacing.xs),
                                    // Row(
                                    //   mainAxisAlignment:
                                    //       MainAxisAlignment.spaceBetween,
                                    //   children: [
                                    //     Text(
                                    //       state.isLogin
                                    //           ? 'RETURNING SENDER'
                                    //           : 'NEW SENDER',
                                    //       style: AppTypography.monoLabel
                                    //           .copyWith(
                                    //             fontSize: 8.5,
                                    //             color: const Color(0xFF64748B),
                                    //             letterSpacing: 0.4,
                                    //           ),
                                    //     ),
                                    //     Text(
                                    //       state.isSuccessAccepted
                                    //           ? 'VERIFIED'
                                    //           : (state.step == AuthStep.code
                                    //                 ? 'AWAITING CODE'
                                    //                 : 'AWAITING VERIFICATION'),
                                    //       style: AppTypography.monoLabel
                                    //           .copyWith(
                                    //             fontSize: 8.5,
                                    //             color: state.isSuccessAccepted
                                    //                 ? AppColors.primary
                                    //                 : const Color(0xFF64748B),
                                    //             letterSpacing: 0.4,
                                    //           ),
                                    //     ),
                                    //   ],
                                    // ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Floating Green Notification Toast at Bottom
                  if (_showOtpSentToast && state.step == AuthStep.code)
                    Positioned(
                      left: 16.0,
                      right: 16.0,
                      bottom: 16.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 12.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D000000),
                              blurRadius: 8.0,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20.0,
                              height: 20.0,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 13.0,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: Text(
                                'Code sent to +91 ${_formatPhone(currentPhone)}',
                                style: AppTypography.bodyRegular.copyWith(
                                  color: const Color(0xFF065F46),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.0,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _showOtpSentToast = false),
                              child: const Icon(
                                Icons.close,
                                size: 16.0,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConsignmentHeader(
    AuthState state,
    String phone,
    double progress,
  ) {
    final displayPhone = phone.isNotEmpty ? phone : '0000000000';

    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand & Copy 1 Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32.0,
                    height: 32.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: const Icon(
                      Icons.hexagon_outlined,
                      color: Colors.white,
                      size: 18.0,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SunGguard',
                        style: AppTypography.headingMedium.copyWith(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'CONSIGNMENT NOTE',
                        style: AppTypography.monoLabelLight.copyWith(
                          fontSize: 8.5,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Text(
                  'COPY 1',
                  style: AppTypography.monoLabelLight.copyWith(
                    fontSize: 8.5,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18.0),

          // SG · 91 · Phone
          Row(
            children: [
              Text(
                'SG',
                style: AppTypography.monoData.copyWith(
                  color: const Color(0xFF64748B),
                  fontSize: 17.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6.0),
              const Text(
                '·',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 18.0),
              ),
              const SizedBox(width: 6.0),
              Text(
                '91',
                style: AppTypography.monoData.copyWith(
                  color: const Color(0xFF64748B),
                  fontSize: 17.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6.0),
              const Text(
                '·',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 18.0),
              ),
              const SizedBox(width: 6.0),
              Text(
                displayPhone,
                style: AppTypography.monoData.copyWith(
                  color: Colors.white,
                  fontSize: 17.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14.0),

          // Route Progress Bar
          Row(
            children: [
              Expanded(
                flex: (progress * 100).toInt().clamp(10, 90),
                child: Container(height: 2.0, color: const Color(0xFF2563EB)),
              ),
              Container(
                width: 14.0,
                height: 14.0,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.view_in_ar,
                  color: Color(0xFF38BDF8),
                  size: 10.0,
                ),
              ),
              Expanded(
                flex: (100 - (progress * 100).toInt()).clamp(10, 90),
                child: Row(
                  children: List.generate(12, (index) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        height: 1.5,
                        color: const Color(0xFF334155),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6.0),

          // Labels below progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.isLogin ? 'YOUR NUMBER' : 'NEW SENDER',
                style: AppTypography.monoLabelLight.copyWith(
                  fontSize: 8.5,
                  color: const Color(0xFF64748B),
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                state.isSuccessAccepted ? 'VERIFIED' : 'VERIFIED',
                style: AppTypography.monoLabelLight.copyWith(
                  fontSize: 8.5,
                  color: const Color(0xFF64748B),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTearDivider() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(height: 1.0, color: const Color(0xFFE2E8F0)),
        Positioned(
          left: -7.0,
          top: -7.0,
          child: Container(
            width: 14.0,
            height: 14.0,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: -7.0,
          top: -7.0,
          child: Container(
            width: 14.0,
            height: 14.0,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSwitcher(AuthState state) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(3.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  context.read<AuthBloc>().add(const AuthModeSwitched('login')),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9.0),
                decoration: BoxDecoration(
                  color: state.isLogin ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9.0),
                  boxShadow: state.isLogin
                      ? const [
                          BoxShadow(
                            color: Color(0x140F172A),
                            blurRadius: 4.0,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'SIGN IN',
                  style: AppTypography.monoLabel.copyWith(
                    color: state.isLogin
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF64748B),
                    fontWeight: state.isLogin
                        ? FontWeight.w800
                        : FontWeight.w600,
                    fontSize: 11.0,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => context.read<AuthBloc>().add(
                const AuthModeSwitched('signup'),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9.0),
                decoration: BoxDecoration(
                  color: !state.isLogin ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9.0),
                  boxShadow: !state.isLogin
                      ? const [
                          BoxShadow(
                            color: Color(0x140F172A),
                            blurRadius: 4.0,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'SIGN UP',
                  style: AppTypography.monoLabel.copyWith(
                    color: !state.isLogin
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF64748B),
                    fontWeight: !state.isLogin
                        ? FontWeight.w800
                        : FontWeight.w600,
                    fontSize: 11.0,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonoCaption(String text) {
    return Text(
      text,
      style: AppTypography.monoLabel.copyWith(
        fontSize: 10.0,
        color: const Color(0xFF475569),
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildNameInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 2.0),
      child: TextField(
        controller: _nameController,
        style: AppTypography.bodyRegular.copyWith(
          color: const Color(0xFF0F172A),
          fontSize: 15.0,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'As it should appear on the label',
          hintStyle: AppTypography.bodyRegular.copyWith(
            color: const Color(0xFF94A3B8),
            fontSize: 14.0,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 2.0),
      child: Row(
        children: [
          Text(
            '+91',
            style: AppTypography.monoData.copyWith(
              color: const Color(0xFF0F172A),
              fontSize: 16.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [TenDigitPhoneInputFormatter()],
              style: AppTypography.monoData.copyWith(
                color: const Color(0xFF0F172A),
                fontSize: 16.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
              decoration: InputDecoration(
                hintText: '98745  12365',
                hintStyle: AppTypography.monoData.copyWith(
                  color: const Color(0xFFCBD5E1),
                  fontSize: 16.0,
                  letterSpacing: 1.5,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build4DigitOtpBoxes() {
    final text = _otpController.text;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Visual 4 Digit Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) {
            final isFilled = index < text.length;
            final isFocused = _otpFocusNode.hasFocus && index == text.length;
            final digit = isFilled ? text[index] : '';

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  left: index == 0 ? 0 : 5.0,
                  right: index == 3 ? 0 : 5.0,
                ),
                height: 64.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: isFocused
                        ? const Color(0xFF0F172A)
                        : (isFilled
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFE2E8F0)),
                    width: isFocused || isFilled ? 2.0 : 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: isFilled
                    ? Text(
                        digit,
                        style: AppTypography.monoData.copyWith(
                          fontSize: 24.0,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      )
                    : (isFocused
                          ? Container(
                              width: 2.0,
                              height: 24.0,
                              color: const Color(0xFF0F172A),
                            )
                          : null),
              ),
            );
          }),
        ),

        // Invisible Overlay TextField for Seamless System Keyboard/Paste/Autofill
        Positioned.fill(
          child: Opacity(
            opacity: 0.0,
            child: TextField(
              controller: _otpController,
              focusNode: _otpFocusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              cursorColor: Colors.transparent,
              showCursor: false,
              enableInteractiveSelection: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimarySubmitButton({
    required String label,
    required bool isLoading,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 50.0,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? const Color(0xFF0F172A)
              : const Color(0xFF6B82A6),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF6B82A6),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        onPressed: isEnabled && !isLoading ? onPressed : null,
        child: isLoading
            ? const SizedBox(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: AppTypography.monoLabel.copyWith(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }

  Widget _buildTermsNotice() {
    return Column(
      children: [
        Text(
          'By countinue, you accept our',
          style: AppTypography.monoLabel.copyWith(
            fontSize: 9.5,
            color: const Color(0xFF94A3B8),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 3.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TERMS',
              style: AppTypography.monoLabel.copyWith(
                fontSize: 10.5,
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 6.0),
            const Text(
              '·',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.0),
            ),
            const SizedBox(width: 6.0),
            Text(
              'PRIVACY',
              style: AppTypography.monoLabel.copyWith(
                fontSize: 10.5,
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtpStepHeader(AuthState state, String phone) {
    return Row(
      children: [
        Container(
          width: 38.0,
          height: 38.0,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.arrow_back,
              size: 18.0,
              color: Color(0xFF0F172A),
            ),
            onPressed: () {
              context.read<AuthBloc>().add(AuthModeSwitched(state.mode));
            },
          ),
        ),
        const SizedBox(width: 12.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the verification code',
              style: AppTypography.headingLarge.copyWith(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: 20.0,
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              'Code sent to +91 ${_formatPhone(phone)}',
              style: AppTypography.monoLabel.copyWith(
                color: const Color(0xFF64748B),
                fontSize: 10.0,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
