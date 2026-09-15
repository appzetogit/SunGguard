import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sungguard/l10n/app_localizations.dart';

import '../../../../core/services/media_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class EditProfilePage extends StatefulWidget {
  final VoidCallback? onBack;

  const EditProfilePage({super.key, this.onBack});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String? _nameError;
  String? _phoneError;
  String? _emailError;

  File? _pickedImageFile;
  bool _isUploadingAvatar = false;
  /// Hosted avatar URL, either loaded from the profile or newly uploaded.
  String _avatarUrl = '';
  final MediaService _mediaService = MediaService();

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  @override
  void initState() {
    super.initState();
    final authUser = context.read<AuthBloc>().state.user;

    _nameCtrl.text = authUser?.name ?? '';
    final rawPhone = authUser?.phone ?? '';
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    _phoneCtrl.text = (digits.startsWith('91') && digits.length > 10)
        ? digits.substring(2)
        : digits;
    _emailCtrl.text = authUser?.email ?? '';
    _avatarUrl = authUser?.avatar ?? '';

    _nameCtrl.addListener(() {
      if (_nameError != null) setState(() => _nameError = null);
    });
    _phoneCtrl.addListener(() {
      if (_phoneError != null) setState(() => _phoneError = null);
    });
    _emailCtrl.addListener(() {
      if (_emailError != null) setState(() => _emailError = null);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSourceType source) async {
    Navigator.of(context).pop();
    final file = source == ImageSourceType.camera
        ? await _mediaService.pickImageFromCamera()
        : await _mediaService.pickImageFromGallery();

    if (file == null) return;

    setState(() {
      _pickedImageFile = file;
      _isUploadingAvatar = true;
    });

    // Upload immediately so the saved profile carries a URL. Holding only the
    // local File meant the chosen picture was discarded on navigation and the
    // server never learned about it.
    final url = await _mediaService.uploadFile(file);
    if (!mounted) return;

    setState(() {
      _isUploadingAvatar = false;
      if (url != null) _avatarUrl = url;
    });

    if (url == null) {
      AppSnackBar.showError(context, "Couldn't upload that photo");
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 18.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                const SizedBox(height: 18.0),
                Text(
                  AppLocalizations.of(context)!.editPhotoTitle,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  leading: Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Color(0xFF1E40AF),
                      size: 22.0,
                    ),
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.editPhotoCamera,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  onTap: () => _pickImage(ImageSourceType.camera),
                ),
                ListTile(
                  leading: Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Color(0xFF0F172A),
                      size: 22.0,
                    ),
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.editPhotoGallery,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  onTap: () => _pickImage(ImageSourceType.gallery),
                ),
                const SizedBox(height: 8.0),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _validateForm() {
    bool isValid = true;
    String? nameErr;
    String? phoneErr;
    String? emailErr;

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      nameErr = 'Please enter your name';
      isValid = false;
    } else if (name.length < 3) {
      nameErr = 'Name must be at least 3 characters long';
      isValid = false;
    } else if (name.length > 50) {
      nameErr = 'Name cannot exceed 50 characters';
      isValid = false;
    }

    final phoneDigits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '').trim();
    if (phoneDigits.isEmpty) {
      phoneErr = 'Please enter your mobile number';
      isValid = false;
    } else if (phoneDigits.length != 10) {
      phoneErr = 'Mobile number must be 10 digits';
      isValid = false;
    } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phoneDigits)) {
      phoneErr = 'Enter a valid 10-digit mobile number';
      isValid = false;
    }

    final email = _emailCtrl.text.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    // Optional on the backend (PUT /customer/profile clears it when empty).
    if (email.isNotEmpty && !emailRegex.hasMatch(email)) {
      emailErr = 'Enter a valid email address';
      isValid = false;
    }

    setState(() {
      _nameError = nameErr;
      _phoneError = phoneErr;
      _emailError = emailErr;
    });

    return isValid;
  }

  void _saveProfile() {
    if (!_validateForm()) {
      AppSnackBar.showError(context, 'Please fix the errors in the form');
      return;
    }

    context.read<ProfileBloc>().add(
      ProfileUpdateRequested(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        avatar: _avatarUrl.isNotEmpty ? _avatarUrl : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state.isUpdated) {
          if (state.updatedUser != null) {
            context.read<AuthBloc>().add(AuthUserUpdated(state.updatedUser!));
          } else {
            context.read<AuthBloc>().add(AuthCheckRequested());
          }
          AppSnackBar.showSuccess(
            context,
            AppLocalizations.of(context)!.editProfileSuccess,
          );
          _handleBack();
        } else if (state.errorMessage != null) {
          AppSnackBar.showError(context, AppLocalizations.of(context)!.error);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              size: 20.0,
              color: Color(0xFF0F172A),
            ),
            onPressed: _handleBack,
          ),
          titleSpacing: 0,
          title: Text(
            AppLocalizations.of(context)!.editProfileTitle,
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
              // 1. Avatar Profile Edit Card
              Container(
                width: double.infinity,
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
                padding: const EdgeInsets.symmetric(
                  vertical: 24.0,
                  horizontal: 20.0,
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isUploadingAvatar ? null : _showImagePickerSheet,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 88.0,
                            height: 88.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 2.0,
                              ),
                            ),
                            child: ClipOval(
                              child: _isUploadingAvatar
                                  ? const Center(
                                      child: SizedBox(
                                        width: 22.0,
                                        height: 22.0,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                    )
                                  : _pickedImageFile != null
                                      ? Image.file(
                                          _pickedImageFile!,
                                          fit: BoxFit.cover,
                                          width: 88.0,
                                          height: 88.0,
                                        )
                                      : (_avatarUrl.isNotEmpty
                                          ? Image.network(
                                              _avatarUrl,
                                              fit: BoxFit.cover,
                                              width: 88.0,
                                              height: 88.0,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                Icons.person_outline_rounded,
                                                size: 44.0,
                                                color: Color(0xFF64748B),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.person_outline_rounded,
                                              size: 44.0,
                                              color: Color(0xFF64748B),
                                            )),
                            ),
                          ),
                          Container(
                            width: 28.0,
                            height: 28.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0F172A),
                              border: Border.all(
                                color: Colors.white,
                                width: 2.0,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 14.0,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      AppLocalizations.of(context)!.edit,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F2552),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22.0),

              // 2. White Form Card
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
                padding: const EdgeInsets.all(20.0),
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FULL NAME
                        _buildFieldLabel(l10n.fullName.toUpperCase()),
                        const SizedBox(height: 6.0),
                        _buildInputField(
                          controller: _nameCtrl,
                          prefixIcon: Icons.person_outline_rounded,
                          hintText: l10n.fullName,
                          errorText: _nameError,
                          maxLength: 50,
                        ),

                        const SizedBox(height: 16.0),

                        // PHONE NUMBER
                        _buildFieldLabel(l10n.phoneNumber.toUpperCase()),
                        const SizedBox(height: 6.0),
                        _buildInputField(
                          controller: _phoneCtrl,
                          prefixIcon: Icons.phone_outlined,
                          hintText: l10n.phoneNumber,
                          keyboardType: TextInputType.phone,
                          errorText: _phoneError,
                        ),

                        const SizedBox(height: 16.0),

                        // EMAIL ADDRESS
                        _buildFieldLabel(l10n.emailAddress.toUpperCase()),
                        const SizedBox(height: 6.0),
                        _buildInputField(
                          controller: _emailCtrl,
                          prefixIcon: Icons.mail_outline_rounded,
                          hintText: l10n.emailAddress,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _emailError,
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 20.0),

              // 3. Save Changes Button
              BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, state) {
                  final l10n = AppLocalizations.of(context)!;
                  return SizedBox(
                    width: double.infinity,
                    height: 48.0,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      onPressed: (state.isLoading || _isUploadingAvatar)
                          ? null
                          : _saveProfile,
                      child: state.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.save_outlined,
                                  size: 18.0,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  l10n.editProfileSave,
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 100.0), // Spacing for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTypography.monoLabel.copyWith(
        fontSize: 10.0,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF64748B),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData prefixIcon,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    int? maxLength,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: hasError ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: hasError
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFE2E8F0),
              width: hasError ? 1.5 : 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Row(
            children: [
              Icon(
                prefixIcon,
                color: hasError
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF94A3B8),
                size: 18.0,
              ),
              const SizedBox(width: 12.0),
              if (keyboardType == TextInputType.phone) ...[
                const Text(
                  '+91 ',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: maxLength != null
                      ? [LengthLimitingTextInputFormatter(maxLength)]
                      : (keyboardType == TextInputType.phone
                            ? [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ]
                            : null),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      fontSize: 13.0,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 5.0),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 13.0,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(width: 4.0),
                Text(
                  errorText,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

enum ImageSourceType { camera, gallery }
