import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sungguard/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../booking/presentation/widgets/outstation_map_picker_dialog.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/user_address_entity.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class AddressesPage extends StatefulWidget {
  final VoidCallback? onBack;

  const AddressesPage({super.key, this.onBack});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
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
    context.read<ProfileBloc>().add(ProfileFetchRequested());
  }

  void _showAddressModal({UserAddressEntity? existingAddress}) {
    final isEditing = existingAddress != null;
    final authUser = context.read<AuthBloc>().state.user;
    String selectedType = existingAddress?.label ?? 'Home';
    final nameCtrl = TextEditingController(
      text: existingAddress?.name.isNotEmpty == true ? existingAddress!.name : (authUser?.name ?? ''),
    );
    final phoneCtrl = TextEditingController(
      text: existingAddress?.phone.isNotEmpty == true ? existingAddress!.phone : (authUser?.phone ?? ''),
    );
    final addrCtrl = TextEditingController(
      text: existingAddress != null
          ? (existingAddress.line.isNotEmpty ? existingAddress.line : existingAddress.fullAddress)
          : '',
    );
    final landmarkCtrl = TextEditingController(text: existingAddress?.landmark ?? '');
    // Coordinates make a saved address usable for booking. Without them the
    // address book is write-only: both booking flows require lat/lng.
    double? pickedLat = existingAddress?.lat;
    double? pickedLng = existingAddress?.lng;
    String pickedFormatted = existingAddress?.formattedAddress ?? '';
    final cityCtrl = TextEditingController(text: existingAddress?.city ?? '');
    final stateCtrl = TextEditingController(text: existingAddress?.state ?? '');
    final pincodeCtrl = TextEditingController(text: existingAddress?.pincode ?? '');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final l10n = AppLocalizations.of(context)!;
            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
              child: Container(
                constraints: BoxConstraints(maxWidth: 480, maxHeight: MediaQuery.of(context).size.height * 0.88),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Header + Close Button
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => Navigator.of(ctx).pop(),
                              child: const Icon(Icons.close, color: Color(0xFF64748B), size: 20.0),
                            ),
                          ),
                          Column(
                            children: [
                              Builder(
                                builder: (context) {
                                  final l10n = AppLocalizations.of(context)!;
                                  return Text(
                                    isEditing ? l10n.addrEditTitle : l10n.addrAddTitle,
                                    style: AppTypography.headingMedium.copyWith(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 4.0),
                              Builder(
                                builder: (context) {
                                  final l10n = AppLocalizations.of(context)!;
                                  return Text(
                                    isEditing ? l10n.addrEditSub : l10n.addrAddSub,
                                    style: const TextStyle(
                                      fontSize: 13.0,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20.0),

                      // 1. Address Type
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context)!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(l10n.addrType),
                              const SizedBox(height: 8.0),
                              Row(
                                children: ['Home', 'Work', 'Other'].map((type) {
                                  final isSelected = selectedType.toLowerCase() == type.toLowerCase();
                                  final localizedType = type == 'Home'
                                      ? l10n.addrTypeHome
                                      : (type == 'Work' ? l10n.addrTypeWork : l10n.addrTypeOther);
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => setModalState(() => selectedType = type),
                                      child: Container(
                                        margin: EdgeInsets.only(right: type != 'Other' ? 8.0 : 0.0),
                                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10.0),
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
                                            width: isSelected ? 1.5 : 1.0,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          localizedType,
                                          style: TextStyle(
                                            fontSize: 13.0,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 16.0),

                              // 2. Full Name
                              _buildFieldLabel(l10n.fullName),
                              const SizedBox(height: 6.0),
                              _buildTextInput(controller: nameCtrl, hintText: l10n.fullName),

                              const SizedBox(height: 14.0),

                              // 3. Phone Number
                              _buildFieldLabel(l10n.phoneNumber),
                              const SizedBox(height: 6.0),
                              _buildTextInput(
                                controller: phoneCtrl,
                                hintText: l10n.phoneNumber,
                                keyboardType: TextInputType.phone,
                              ),

                              const SizedBox(height: 14.0),

                              // 4. Address
                              _buildFieldLabel(l10n.address),
                              const SizedBox(height: 6.0),
                              _buildTextInput(controller: addrCtrl, hintText: l10n.address, minLines: 2, maxLines: 3),

                              const SizedBox(height: 14.0),

                              // 5. Nearest Landmark
                              _buildFieldLabel(l10n.addrLandmarkOpt),
                              const SizedBox(height: 6.0),
                              _buildTextInput(controller: landmarkCtrl, hintText: l10n.addrLandmarkOpt),

                              const SizedBox(height: 14.0),

                              // 6. City & State
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel(l10n.addrCity),
                                        const SizedBox(height: 6.0),
                                        _buildTextInput(controller: cityCtrl, hintText: l10n.addrCity),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel(l10n.addrState),
                                        const SizedBox(height: 6.0),
                                        _buildTextInput(controller: stateCtrl, hintText: l10n.addrState),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14.0),

                              // 7. Pincode
                              _buildFieldLabel(l10n.addrPincode),
                              const SizedBox(height: 6.0),
                              _buildTextInput(
                                controller: pincodeCtrl,
                                hintText: l10n.addrPincode,
                                keyboardType: TextInputType.number,
                              ),

                              const SizedBox(height: 14.0),

                              // 8. Map position. Stored as location:{lat,lng},
                              // which is what lets this address be picked
                              // straight from a booking screen later.
                              _buildFieldLabel('MAP POSITION'),
                              const SizedBox(height: 6.0),
                              GestureDetector(
                                onTap: () async {
                                  await showDialog<void>(
                                    context: context,
                                    barrierDismissible: true,
                                    builder: (dialogCtx) =>
                                        OutstationMapPickerDialog(
                                      initialLat: pickedLat ?? 22.7560,
                                      initialLng: pickedLng ?? 75.8657,
                                      onLocationConfirmed:
                                          (lat, lng, address, details) {
                                        setModalState(() {
                                          pickedLat = lat;
                                          pickedLng = lng;
                                          pickedFormatted =
                                              details?.formattedAddress
                                                          .isNotEmpty ==
                                                      true
                                                  ? details!.formattedAddress
                                                  : address;
                                          if (addrCtrl.text.trim().isEmpty) {
                                            addrCtrl.text = pickedFormatted;
                                          }
                                          if (cityCtrl.text.trim().isEmpty &&
                                              details?.city != null) {
                                            cityCtrl.text = details!.city!;
                                          }
                                          if (stateCtrl.text.trim().isEmpty &&
                                              details?.state != null) {
                                            stateCtrl.text = details!.state!;
                                          }
                                          if (pincodeCtrl.text.trim().isEmpty &&
                                              details?.pincode != null) {
                                            pincodeCtrl.text =
                                                details!.pincode!;
                                          }
                                        });
                                      },
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(14.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(
                                      color: (pickedLat != null &&
                                              pickedLng != null)
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        (pickedLat != null && pickedLng != null)
                                            ? Icons.check_circle_outline
                                            : Icons.map_outlined,
                                        size: 19.0,
                                        color: (pickedLat != null &&
                                                pickedLng != null)
                                            ? const Color(0xFF059669)
                                            : const Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(width: 10.0),
                                      Expanded(
                                        child: Text(
                                          (pickedLat != null &&
                                                  pickedLng != null)
                                              ? 'Pinned · ${pickedLat!.toStringAsFixed(4)}, ${pickedLng!.toStringAsFixed(4)}'
                                              : 'Pin this address on the map',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: (pickedLat != null &&
                                                    pickedLng != null)
                                                ? const Color(0xFF0F172A)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        size: 19.0,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 22.0),

                      // Action Buttons: Save/Update & Cancel
                      SizedBox(
                        width: double.infinity,
                        height: 46.0,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                          ),
                          onPressed: () {
                            final full = addrCtrl.text.trim();
                            // Coordinates are optional here so an existing
                            // address can still be edited, but without them
                            // the entry cannot later be used to book.
                            if (full.isEmpty) {
                              AppSnackBar.showError(context, l10n.address);
                              return;
                            }

                            final combinedAddress = full;

                            final addressEntity = UserAddressEntity(
                              id: existingAddress?.id ?? 'addr_${DateTime.now().millisecondsSinceEpoch}',
                              label: selectedType,
                              fullAddress: combinedAddress,
                              line: full,
                              landmark: landmarkCtrl.text.trim(),
                              city: cityCtrl.text.trim(),
                              state: stateCtrl.text.trim(),
                              pincode: pincodeCtrl.text.trim(),
                              name: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              isDefault: true,
                              lat: pickedLat,
                              lng: pickedLng,
                              formattedAddress: pickedFormatted,
                            );

                            if (isEditing) {
                              context.read<ProfileBloc>().add(ProfileEditAddressRequested(addressEntity));
                              AppSnackBar.showSuccess(context, l10n.success);
                            } else {
                              context.read<ProfileBloc>().add(ProfileAddAddressRequested(addressEntity));
                              AppSnackBar.showSuccess(context, l10n.success);
                            }

                            Navigator.of(ctx).pop();
                          },
                          child: Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context)!;
                              return Text(
                                isEditing ? l10n.addrUpdateBtn : l10n.addrSaveBtn,
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 8.0),

                      SizedBox(
                        width: double.infinity,
                        height: 44.0,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                            backgroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Builder(
                            builder: (context) {
                              return Text(
                                AppLocalizations.of(context)!.cancel,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              );
                            },
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
      },
    );
  }

  void _showDeleteConfirmationDialog(UserAddressEntity address) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Close Button & Header
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: const Icon(Icons.close, color: Color(0xFF64748B), size: 20.0),
                      ),
                    ),
                    Text(
                      l10n.addrDeleteTitle,
                      style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w800, color: Color(0xFFEF4444)),
                    ),
                  ],
                ),

                const SizedBox(height: 12.0),

                Text(
                  l10n.addrDeleteConfirm,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF64748B),
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 18.0),

                // Address Preview Box
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address.label,
                        style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        address.fullAddress,
                        style: const TextStyle(fontSize: 13.0, color: Color(0xFF64748B), fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20.0),

                // Delete Button (Red)
                SizedBox(
                  width: double.infinity,
                  height: 44.0,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    ),
                    onPressed: () {
                      context.read<ProfileBloc>().add(ProfileDeleteAddressRequested(address.id));
                      Navigator.of(ctx).pop();
                      AppSnackBar.showSuccess(context, AppLocalizations.of(context)!.success);
                    },
                    child: Text(
                      l10n.delete,
                      style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 8.0),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  height: 44.0,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                      backgroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      l10n.cancel,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: keyboardType == TextInputType.phone
            ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]
            : null,
        minLines: minLines,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 13.0, color: Color(0xFF94A3B8), fontWeight: FontWeight.w400),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  IconData _getAddressIcon(String label) {
    switch (label.toLowerCase()) {
      case 'work':
        return Icons.work_outline_rounded;
      case 'other':
        return Icons.location_on_outlined;
      case 'home':
      default:
        return Icons.home_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 20.0),
          onPressed: _handleBack,
        ),
        titleSpacing: 0,
        title: Text(
          l10n.addressesTitle,
          style: AppTypography.headingLarge.copyWith(
            fontSize: 18.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          final addresses = state.addresses;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // 1. Add New Address Card Button
                GestureDetector(
                  onTap: () => _showAddressModal(),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 10.0, offset: Offset(0, 3))],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28.0,
                          height: 28.0,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.add, color: Color(0xFF0F172A), size: 18.0),
                        ),
                        const SizedBox(width: 10.0),
                        Text(
                          l10n.addressesAddNew,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // 2. Saved Addresses List / Empty State / Loading State
                if (state.isLoading)
                  const Column(children: [AddressCardSkeleton(), AddressCardSkeleton(), AddressCardSkeleton()])
                else if (addresses.isEmpty)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 14.0, offset: Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_outlined, color: Color(0xFF94A3B8), size: 36.0),
                        const SizedBox(height: 12.0),
                        Text(
                          l10n.addressesNoSaved,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: addresses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                    itemBuilder: (context, index) {
                      final item = addresses[index];
                      final isDefault = index == 0 || item.isDefault;

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x060F172A), blurRadius: 10.0, offset: Offset(0, 3)),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            // Main Card Content
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Row: Icon + Address details
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Icon Box
                                      Container(
                                        width: 42.0,
                                        height: 42.0,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          _getAddressIcon(item.label),
                                          color: const Color(0xFF0F172A),
                                          size: 22.0,
                                        ),
                                      ),
                                      const SizedBox(width: 14.0),

                                      // Text Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.label,
                                              style: const TextStyle(
                                                fontSize: 15.0,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 3.0),
                                            Text(
                                              item.name.isNotEmpty ? item.name : 'Varun',
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 3.0),
                                            Text(
                                              item.fullAddress,
                                              style: const TextStyle(
                                                fontSize: 13.0,
                                                color: Color(0xFF64748B),
                                                height: 1.35,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            const SizedBox(height: 4.0),
                                            RichText(
                                              text: TextSpan(
                                                style: const TextStyle(fontSize: 13.0, color: Color(0xFF475569)),
                                                children: [
                                                  const TextSpan(
                                                    text: 'Phone: ',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w700,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                  TextSpan(text: item.phone.isNotEmpty ? item.phone : '+919638527410'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 14.0),

                                  // Action Buttons: Edit & Delete
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 36.0,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(8.0),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(8.0),
                                            onTap: () => _showAddressModal(existingAddress: item),
                                            child: const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.edit_outlined, size: 15.0, color: Color(0xFF0F172A)),
                                                SizedBox(width: 6.0),
                                                Text(
                                                  'Edit',
                                                  style: TextStyle(
                                                    fontSize: 13.0,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10.0),
                                      Expanded(
                                        child: Container(
                                          height: 36.0,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(8.0),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(8.0),
                                            onTap: () => _showDeleteConfirmationDialog(item),
                                            child: const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 15.0,
                                                  color: Color(0xFF0F172A),
                                                ),
                                                SizedBox(width: 6.0),
                                                Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    fontSize: 13.0,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Top-Right DEFAULT Badge
                            if (isDefault)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0F172A),
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(16.0),
                                      bottomLeft: Radius.circular(8.0),
                                    ),
                                  ),
                                  child: const Text(
                                    'DEFAULT',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 100.0), // Spacing for bottom nav
              ],
            ),
          );
        },
      ),
    );
  }
}
