import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sungguard/l10n/app_localizations.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/services/razorpay_checkout_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/ink_barcode.dart';
import '../../../../core/widgets/perforation_line.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/models/city_parcel_booking_request.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';
import '../widgets/embedded_google_map_card.dart';

class CityParcelBookingPage extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(String parcelId)? onBookingSuccess;

  const CityParcelBookingPage({super.key, this.onBack, this.onBookingSuccess});

  @override
  State<CityParcelBookingPage> createState() => _CityParcelBookingPageState();
}

class _CityParcelBookingPageState extends State<CityParcelBookingPage> {
  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _handleSuccess(String parcelId) {
    context.read<BookingBloc>().add(BookingResetRequested());
    if (widget.onBookingSuccess != null) {
      widget.onBookingSuccess!(parcelId);
    } else {
      context.pushReplacement('/parcel/local/track/$parcelId');
    }
  }

  final RazorpayCheckoutService _checkout = RazorpayCheckoutService();

  // Step 0: From Controllers
  final _senderNameCtrl = TextEditingController();
  final _senderPhoneCtrl = TextEditingController();
  final _pickupAddrCtrl = TextEditingController();
  final _pickupLineCtrl = TextEditingController();
  final _pickupLandmarkCtrl = TextEditingController();
  final _pickupPincodeCtrl = TextEditingController();
  double _pickupLat = 0.0;
  double _pickupLng = 0.0;

  // Step 1: To Controllers
  final _receiverNameCtrl = TextEditingController();
  final _receiverPhoneCtrl = TextEditingController();
  final _receiverAltPhoneCtrl = TextEditingController();
  final _dropAddrCtrl = TextEditingController();
  final _dropLineCtrl = TextEditingController();
  final _dropLandmarkCtrl = TextEditingController();
  final _dropPincodeCtrl = TextEditingController();
  final _couponCtrl = TextEditingController();
  double _dropLat = 0.0;
  double _dropLng = 0.0;

  // Step 2: Package Controllers - API-driven (labels shown, values sent)
  String _selectedCategory = 'Documents';
  String _selectedCategoryValue = 'document';
  // ignore: unused_field - kept for API trace, values used via _categories/_categoryValues
  List<Map<String, dynamic>> _apiPackageTypes = [];
  String _packagePlaceholder = 'Keys, documents, a birthday gift...';
  double _cityMaxWeightKg = 20.0;
  /// From GET /city-parcel/booking-config — previously discarded.
  double _expressCharge = 0.0;
  bool _cityDeliveryEnabled = true;
  final _weightCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _declaredValueCtrl = TextEditingController();
  bool _anyoneCanCollect = false;

  // Step 3: Payment Controllers
  String _selectedPaymentMethod = 'UPI'; // 'UPI', 'CARD', 'COD'

  List<String> _categories = [
    'Documents',
    'Food',
    'Clothes',
    'Electronics',
    'Medicine',
    'Something else',
  ];
  // value mapping kept parallel to labels
  List<String> _categoryValues = [
    'document',
    'food',
    'clothes',
    'electronics',
    'medicine',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final bookingState = context.read<BookingBloc>().state;

    // Sender Name & Phone
    _senderNameCtrl.text = bookingState.sender.name.isNotEmpty
        ? bookingState.sender.name
        : (authState.user?.name ?? '');
    _senderPhoneCtrl.text = bookingState.sender.phone.isNotEmpty
        ? bookingState.sender.phone
        : (authState.user?.phone ?? '');

    // Pickup Address
    if (bookingState.pickup.fullAddress.isNotEmpty) {
      _pickupAddrCtrl.text = bookingState.pickup.fullAddress;
      _pickupLineCtrl.text = bookingState.pickup.line;
      _pickupLandmarkCtrl.text = bookingState.pickup.landmark;
      _pickupPincodeCtrl.text = bookingState.pickup.pincode;
      if (bookingState.pickup.lat != null) {
        _pickupLat = bookingState.pickup.lat!;
      }
      if (bookingState.pickup.lng != null) {
        _pickupLng = bookingState.pickup.lng!;
      }
    } else {
      final cached = MapsService.cachedLocation;
      if (cached != null) {
        _pickupAddrCtrl.text = cached.formattedAddress;
        _pickupLat = cached.latitude;
        _pickupLng = cached.longitude;
        if (cached.street != null || cached.area != null) {
          _pickupLandmarkCtrl.text = cached.area ?? cached.street ?? '';
        }
      }
    }

    // Receiver & Drop Address
    if (bookingState.receiver.name.isNotEmpty) {
      _receiverNameCtrl.text = bookingState.receiver.name;
    }
    if (bookingState.receiver.phone.isNotEmpty) {
      _receiverPhoneCtrl.text = bookingState.receiver.phone;
    }
    if (bookingState.drop.fullAddress.isNotEmpty) {
      _dropAddrCtrl.text = bookingState.drop.fullAddress;
      _dropLineCtrl.text = bookingState.drop.line;
      _dropLandmarkCtrl.text = bookingState.drop.landmark;
      _dropPincodeCtrl.text = bookingState.drop.pincode;
      if (bookingState.drop.lat != null) _dropLat = bookingState.drop.lat!;
      if (bookingState.drop.lng != null) _dropLng = bookingState.drop.lng!;
    }

    // Package & Payment - map API value -> label (supports both old label save and new value)
    if (bookingState.package.packageType.isNotEmpty) {
      final raw = bookingState.package.packageType.trim();
      // try value match first
      final vIdx = _categoryValues.indexWhere((v) => v.toLowerCase() == raw.toLowerCase());
      if (vIdx != -1) {
        _selectedCategory = _categories[vIdx];
        _selectedCategoryValue = _categoryValues[vIdx];
      } else {
        // fallback treat raw as label
        _selectedCategory = raw;
        final lIdx = _categories.indexWhere((l) => l.toLowerCase() == raw.toLowerCase());
        _selectedCategoryValue = lIdx != -1 ? _categoryValues[lIdx] : raw.toLowerCase();
      }
    }
    if (bookingState.package.weightKg > 0) {
      _weightCtrl.text = bookingState.package.weightKg.toString();
    }
    if (bookingState.package.description.isNotEmpty) {
      _descCtrl.text = bookingState.package.description;
    }
    // The web booking offers UPI, CARD and COD only.
    if (['UPI', 'CARD', 'COD'].contains(bookingState.paymentMethod)) {
      _selectedPaymentMethod = bookingState.paymentMethod;
    }

    _syncPickup();
    _syncDrop();
    _loadCityBookingConfig();
    if (_selectedPaymentMethod != bookingState.paymentMethod) {
      context.read<BookingBloc>().add(
            BookingPaymentMethodSelected(_selectedPaymentMethod),
          );
    }
  }

  Future<void> _loadCityBookingConfig() async {
    try {
      final client = ApiClient.createDefault();
      final res = await client.get(ApiEndpoints.cityParcelBookingConfig);
      final data = (res is Map) ? (res['result'] ?? res['data'] ?? res) : null;
      if (data is Map) {
        final types = (data['packageTypes'] as List?) ?? [];
        final parsed = types.whereType<Map>().map((e) {
          final m = Map<String, dynamic>.from(e);
          return {
            'value': m['value']?.toString() ?? '',
            'label': m['label']?.toString() ?? '',
            'isActive': m['isActive'] != false,
          };
        }).where((e) => e['label'].toString().isNotEmpty && e['isActive'] == true).toList();
        if (parsed.isNotEmpty && mounted) {
          setState(() {
            _apiPackageTypes = parsed;
            _categories = parsed.map((e) => e['label'] as String).toList();
            _categoryValues = parsed.map((e) => e['value'] as String).toList();
            if (!_categories.contains(_selectedCategory)) {
              _selectedCategory = _categories.first;
              _selectedCategoryValue = _categoryValues.first;
            } else {
              final idx = _categories.indexOf(_selectedCategory);
              if (idx >= 0) _selectedCategoryValue = _categoryValues[idx];
            }
            if (data['packageDescriptionPlaceholder'] != null) {
              _packagePlaceholder = data['packageDescriptionPlaceholder'].toString();
            }
            if (data['maxWeightKg'] != null) {
              _cityMaxWeightKg = (data['maxWeightKg'] as num).toDouble();
            }
            if (data['expressCharge'] != null) {
              _expressCharge = (data['expressCharge'] as num).toDouble();
            }
          });
          _syncPackage();
        } else if (data['packageDescriptionPlaceholder'] != null && mounted) {
          setState(() => _packagePlaceholder = data['packageDescriptionPlaceholder'].toString());
        }

        // The backend can switch city delivery off entirely. Booking against a
        // disabled service fails at create time with nothing the customer can
        // do about it, so say so up front.
        if (data['isEnabled'] == false && mounted) {
          setState(() => _cityDeliveryEnabled = false);
          AppSnackBar.showError(
            context,
            'City delivery is unavailable right now.',
          );
        }
        if (data['expressCharge'] != null && mounted) {
          setState(
            () => _expressCharge = (data['expressCharge'] as num).toDouble(),
          );
        }
      }
    } catch (_) {}
  }

  String _sanitizeCityName(String raw) {
    var c = raw.replaceAll(RegExp(r'[0-9]'), '').trim().replaceAll(RegExp(r'\s+'), ' ');
    c = c.replaceAll(RegExp(r"[^\p{L}\p{M}\s.'-]", unicode: true), '').trim();
    if (c.length < 2) return 'Customer';
    if (c.length > 80) c = c.substring(0, 80).trim();
    if (!RegExp(r'\p{L}', unicode: true).hasMatch(c)) return 'Customer';
    return c;
  }

  @override
  void dispose() {
    _senderNameCtrl.dispose();
    _senderPhoneCtrl.dispose();
    _pickupAddrCtrl.dispose();
    _pickupLineCtrl.dispose();
    _pickupLandmarkCtrl.dispose();
    _pickupPincodeCtrl.dispose();
    _dropPincodeCtrl.dispose();
    _couponCtrl.dispose();
    _receiverNameCtrl.dispose();
    _receiverPhoneCtrl.dispose();
    _dropAddrCtrl.dispose();
    _dropLineCtrl.dispose();
    _dropLandmarkCtrl.dispose();
    _receiverAltPhoneCtrl.dispose();
    _weightCtrl.dispose();
    _descCtrl.dispose();
    _declaredValueCtrl.dispose();
    super.dispose();
  }

  void _syncPickup() {
    context.read<BookingBloc>().add(
      BookingPickupUpdated(
        pickup: AddressData(
          fullAddress: _pickupAddrCtrl.text,
          line: _pickupLineCtrl.text,
          landmark: _pickupLandmarkCtrl.text,
          lat: _pickupLat != 0.0 ? _pickupLat : null,
          lng: _pickupLng != 0.0 ? _pickupLng : null,
          pincode: _pickupPincodeCtrl.text.trim(),
        ),
        sender: PersonData(
          name: _sanitizeCityName(_senderNameCtrl.text),
          phone: _senderPhoneCtrl.text.trim().replaceAll(RegExp(r'[\s-]'), ''),
        ),
      ),
    );
  }

  void _syncDrop() {
    context.read<BookingBloc>().add(
      BookingDropUpdated(
        drop: AddressData(
          fullAddress: _dropAddrCtrl.text,
          line: _dropLineCtrl.text,
          landmark: _dropLandmarkCtrl.text,
          lat: _dropLat != 0.0 ? _dropLat : null,
          lng: _dropLng != 0.0 ? _dropLng : null,
          pincode: _dropPincodeCtrl.text.trim(),
        ),
        receiver: PersonData(
          name: _sanitizeCityName(_receiverNameCtrl.text),
          phone: _receiverPhoneCtrl.text.trim().replaceAll(RegExp(r'[\s-]'), ''),
          altPhone: _receiverAltPhoneCtrl.text.trim().replaceAll(
            RegExp(r'[\s-]'),
            '',
          ),
          // The form has always asked this; it now actually reaches the
          // server's receiver.allowAlternate field instead of being dropped.
          allowAlternate: _anyoneCanCollect,
        ),
      ),
    );
  }

  /// Guards against the listener re-entering checkout while the sheet is up.
  bool _checkoutOpen = false;

  /// Hands the server-issued order to Razorpay, then posts the signature back
  /// so the backend can release the parcel to riders.
  Future<void> _openCheckout(BookingState state) async {
    final order = state.pendingOrder;
    final parcelId = state.createdParcelId;
    if (order == null || parcelId == null || _checkoutOpen) return;

    _checkoutOpen = true;
    final bloc = context.read<BookingBloc>();
    final authUser = context.read<AuthBloc>().state.user;

    try {
      final result = await _checkout.open(
        order: order,
        description: 'SunGguard city delivery',
        contact: authUser?.phone ?? _senderPhoneCtrl.text,
        email: authUser?.email ?? '',
      );

      if (!mounted) return;

      if (result.success &&
          result.paymentId != null &&
          result.signature != null) {
        bloc.add(
          BookingVerifyPaymentRequested(
            parcelId: parcelId,
            razorpayOrderId: result.orderId ?? order.orderId,
            razorpayPaymentId: result.paymentId!,
            razorpaySignature: result.signature!,
          ),
        );
      } else {
        bloc.add(
          BookingPaymentFailed(
            message: result.cancelled
                ? 'Payment cancelled. Your booking is saved — pay to confirm it.'
                : (result.message ?? 'Payment failed'),
          ),
        );
      }
    } finally {
      _checkoutOpen = false;
    }
  }

  void _syncPackage() {
    final weight = double.tryParse(_weightCtrl.text) ?? 0.0;
    // send API value, not label — keeps payload pro & matches backend config values
    final pkgValue = _selectedCategoryValue.isNotEmpty
        ? _selectedCategoryValue
        : (_categoryValues.isNotEmpty ? _categoryValues.first : _selectedCategory.toLowerCase());
    context.read<BookingBloc>().add(
      BookingPackageUpdated(
        PackageData(
          packageType: pkgValue,
          weightKg: weight,
          description: _descCtrl.text,
          declaredValue: double.tryParse(_declaredValueCtrl.text.trim()) ?? 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingBloc, BookingState>(
      listenWhen: (previous, current) =>
          previous.paymentStage != current.paymentStage ||
          previous.errorMessage != current.errorMessage ||
          previous.serviceabilityMessage != current.serviceabilityMessage,
      listener: (context, state) {
        // Only a confirmed booking may navigate. An online booking is created
        // before it is paid for, so keying off createdParcelId alone sent the
        // customer to a tracking screen for a parcel the backend had not
        // released to any rider.
        if (state.paymentStage == BookingPaymentStage.confirmed &&
            state.createdParcelId != null) {
          _handleSuccess(state.createdParcelId!);
          return;
        }

        if (state.paymentStage == BookingPaymentStage.awaitingCheckout &&
            state.pendingOrder != null) {
          _openCheckout(state);
          return;
        }

        if (state.paymentStage == BookingPaymentStage.failed &&
            state.paymentMessage != null) {
          AppSnackBar.showError(context, state.paymentMessage!);
        }

        if (state.serviceabilityMessage != null) {
          AppSnackBar.showError(context, state.serviceabilityMessage!);
        }

        if (state.errorMessage != null) {
          final l10n = AppLocalizations.of(context)!;
          AppSnackBar.showError(
            context,
            _localizedBookingError(state.errorMessage!, l10n),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Color(0xFF0F172A),
                size: 20.0,
              ),
              onPressed: () {
                if (state.currentStep > 0) {
                  context.read<BookingBloc>().add(
                    BookingStepChanged(state.currentStep - 1),
                  );
                } else {
                  _handleBack();
                }
              },
            ),
            centerTitle: true,
            title: Text(
              AppLocalizations.of(context)!.bookingCityTitle,
              style: AppTypography.headingLarge.copyWith(
                fontSize: 18.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: TextButton(
                  onPressed: _handleBack,
                  child: Text(
                    AppLocalizations.of(context)!.cancel.toUpperCase(),
                    style: AppTypography.monoLabel.copyWith(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Stepper & Draft Waybill Header Card
                _buildDraftWaybillCard(state),

                const SizedBox(height: AppSpacing.lg),

                // 2. Step Title
                _buildStepTitle(state.currentStep),

                const SizedBox(height: AppSpacing.md),

                // 3. Step Content
                if (state.currentStep == 0) _buildStepFrom(state),
                if (state.currentStep == 1) _buildStepTo(state),
                if (state.currentStep == 2) _buildStepWhat(state),
                if (state.currentStep == 3) _buildStepPay(state),

                const SizedBox(height: 20.0),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomAction(state),
        );
      },
    );
  }

  Widget _buildDraftWaybillCard(BookingState state) {
    final l10n = AppLocalizations.of(context)!;
    final stepNames = [l10n.stepFrom, l10n.stepTo, l10n.stepWhat, l10n.stepPay];
    final fare = state.payableTotal;

    return Container(
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
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 Stepper Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(stepNames.length, (index) {
              final isCurrent = index == state.currentStep;
              final isPast = index < state.currentStep;

              return Column(
                children: [
                  Container(
                    width: 34.0,
                    height: 34.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPast ? const Color(0xFF10B981) : Colors.white,
                      border: Border.all(
                        color: isPast
                            ? const Color(0xFF10B981)
                            : (isCurrent
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFCBD5E1)),
                        width: isCurrent ? 2.0 : 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isPast
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18.0,
                          )
                        : (isCurrent
                              ? Container(
                                  width: 10.0,
                                  height: 10.0,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF0F172A),
                                  ),
                                )
                              : null),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    stepNames[index],
                    style: AppTypography.monoLabel.copyWith(
                      fontSize: 10.0,
                      fontWeight: isCurrent || isPast
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isCurrent || isPast
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF64748B),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              );
            }),
          ),

          const SizedBox(height: 14.0),

          // Dashed Divider
          const PerforationLine(
            color: Color(0xFFE2E8F0),
            dashWidth: 4.0,
            dashGap: 4.0,
          ),

          const SizedBox(height: 12.0),

          // Draft Waybill & Estimate Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.draftWaybill,
                    style: AppTypography.monoLabel.copyWith(
                      fontSize: 9.0,
                      color: const Color(0xFF64748B),
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  const InkBarcode(
                    seed: 'DRAFT770',
                    ratio: 0.65,
                    color: Color(0xFF0F172A),
                    height: 24.0,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.estimate,
                    style: AppTypography.monoLabel.copyWith(
                      fontSize: 9.0,
                      color: const Color(0xFF64748B),
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    '₹${fare.toStringAsFixed(2)}',
                    style: AppTypography.monoData.copyWith(
                      fontSize: 22.0,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepTitle(int step) {
    final l10n = AppLocalizations.of(context)!;
    String title = l10n.stepQuestionCollect;
    if (step == 1) title = l10n.stepQuestionGoing;
    if (step == 2) title = l10n.stepQuestionCarrying;
    if (step == 3) title = l10n.stepQuestionPay;

    return Text(
      title,
      style: AppTypography.headingLarge.copyWith(
        fontSize: 22.0,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF0F172A),
      ),
    );
  }

  /// Optional, but when present must match the server's `^[1-9]\d{5}$`.
  bool _isValidPincode(String value) =>
      value.trim().isEmpty || AddressData.pincodePattern.hasMatch(value.trim());

  bool _isSameLocation({
    required String pickupAddr,
    required double pickupLat,
    required double pickupLng,
    required String dropAddr,
    required double dropLat,
    required double dropLng,
  }) {
    final pAddr = pickupAddr.trim().toLowerCase();
    final dAddr = dropAddr.trim().toLowerCase();

    if (pAddr.isNotEmpty && dAddr.isNotEmpty && pAddr == dAddr) {
      return true;
    }

    if (pickupLat != 0.0 &&
        pickupLng != 0.0 &&
        dropLat != 0.0 &&
        dropLng != 0.0) {
      final latDiff = (pickupLat - dropLat).abs();
      final lngDiff = (pickupLng - dropLng).abs();
      if (latDiff < 0.0001 && lngDiff < 0.0001) {
        return true;
      }
    }

    return false;
  }

  // STEP 1: FROM
  Widget _buildStepFrom(BookingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Real Google Map Card (Inline search + Live Map + Panning)
        EmbeddedGoogleMapCard(
          initialAddress: _pickupAddrCtrl.text,
          initialLat: _pickupLat,
          initialLng: _pickupLng,
          placeholderHint: AppLocalizations.of(context)!.searchAddressHint,
          onLocationChanged: (address, details) {
            final newLat = details?.latitude ?? 0.0;
            final newLng = details?.longitude ?? 0.0;

            if (_isSameLocation(
              pickupAddr: address,
              pickupLat: newLat,
              pickupLng: newLng,
              dropAddr: _dropAddrCtrl.text,
              dropLat: _dropLat,
              dropLng: _dropLng,
            )) {
              AppSnackBar.showError(
                context,
                'Pickup and drop look like the same place',
              );
              setState(() {
                _dropAddrCtrl.clear();
                _dropLat = 0.0;
                _dropLng = 0.0;
                _dropLandmarkCtrl.clear();
              });
              _syncDrop();
            }

            setState(() {
              _pickupAddrCtrl.text = address;
              if (details != null) {
                _pickupLat = newLat;
                _pickupLng = newLng;
              }
              if (details?.street != null || details?.area != null) {
                _pickupLandmarkCtrl.text =
                    details?.area ?? details?.street ?? '';
              }
            });
            _syncPickup();
            // Ask now, while the map is still on screen, instead of letting
            // the customer discover it at the payment step.
            if (_pickupLat != 0.0 && _pickupLng != 0.0) {
              context.read<BookingBloc>().add(
                    BookingZoneCheckRequested(
                      lat: _pickupLat,
                      lng: _pickupLng,
                      isPickup: true,
                    ),
                  );
            }
          },
        ),

        const SizedBox(height: AppSpacing.lg),

        // Sender Details Form Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldCaption(AppLocalizations.of(context)!.senderLabel),
              const SizedBox(height: 6.0),
              _buildFilledBox(
                icon: Icons.person_outline,
                controller: _senderNameCtrl,
                hint: AppLocalizations.of(context)!.fullName,
                onChanged: (_) => _syncPickup(),
              ),

              const SizedBox(height: AppSpacing.md),

              _buildFieldCaption(AppLocalizations.of(context)!.phoneLabel),
              const SizedBox(height: 6.0),
              _buildFilledBox(
                icon: Icons.phone_outlined,
                controller: _senderPhoneCtrl,
                keyboardType: TextInputType.phone,
                hint: '+91 00000 00000',
                onChanged: (_) => _syncPickup(),
              ),

              const SizedBox(height: AppSpacing.md),

              _buildFieldCaption(AppLocalizations.of(context)!.houseFlatFloor),
              const SizedBox(height: 6.0),
              _buildSimpleBox(
                controller: _pickupLineCtrl,
                hint: AppLocalizations.of(context)!.houseFlatHint,
                onChanged: (_) => _syncPickup(),
              ),
              const SizedBox(height: 4.0),
              Text(
                AppLocalizations.of(context)!.houseHelperText,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11.5,
                  color: const Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              _buildFieldCaption(AppLocalizations.of(context)!.landmarkLabel),
              const SizedBox(height: 6.0),
              _buildSimpleBox(
                controller: _pickupLandmarkCtrl,
                hint: AppLocalizations.of(context)!.landmarkHint,
                onChanged: (_) => _syncPickup(),
              ),
              const SizedBox(height: 4.0),
              Text(
                AppLocalizations.of(context)!.landmarkHelperText,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11.5,
                  color: const Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              _buildFieldCaption('PINCODE (OPTIONAL)'),
              const SizedBox(height: 6.0),
              _buildSimpleBox(
                controller: _pickupPincodeCtrl,
                hint: '6-digit pincode',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (_) => _syncPickup(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 2: TO
  Widget _buildStepTo(BookingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Real Google Map Card (Inline search + Live Map + Panning)
        EmbeddedGoogleMapCard(
          initialAddress: _dropAddrCtrl.text,
          initialLat: _dropLat,
          initialLng: _dropLng,
          placeholderHint: AppLocalizations.of(context)!.searchAddressHint,
          onLocationChanged: (address, details) {
            final newLat = details?.latitude ?? 0.0;
            final newLng = details?.longitude ?? 0.0;

            if (_isSameLocation(
              pickupAddr: _pickupAddrCtrl.text,
              pickupLat: _pickupLat,
              pickupLng: _pickupLng,
              dropAddr: address,
              dropLat: newLat,
              dropLng: newLng,
            )) {
              AppSnackBar.showError(
                context,
                'Pickup and drop look like the same place',
              );
              setState(() {
                _dropAddrCtrl.clear();
                _dropLat = 0.0;
                _dropLng = 0.0;
                _dropLandmarkCtrl.clear();
              });
              _syncDrop();
              return;
            }

            setState(() {
              _dropAddrCtrl.text = address;
              if (details != null) {
                _dropLat = newLat;
                _dropLng = newLng;
              }
              if (details?.street != null || details?.area != null) {
                _dropLandmarkCtrl.text = details?.area ?? details?.street ?? '';
              }
            });
            _syncDrop();
            if (_dropLat != 0.0 && _dropLng != 0.0) {
              context.read<BookingBloc>().add(
                    BookingZoneCheckRequested(
                      lat: _dropLat,
                      lng: _dropLng,
                      isPickup: false,
                    ),
                  );
            }
          },
        ),

        const SizedBox(height: AppSpacing.lg),

        // Receiver Details Form Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldCaption(AppLocalizations.of(context)!.receiverLabel),
              const SizedBox(height: 6.0),
              _buildFilledBox(
                icon: Icons.person_outline,
                controller: _receiverNameCtrl,
                hint: AppLocalizations.of(context)!.fullName,
                onChanged: (_) => _syncDrop(),
              ),

              const SizedBox(height: AppSpacing.md),

              _buildFieldCaption(
                AppLocalizations.of(context)!.recipientPhoneLabel,
              ),
              const SizedBox(height: 6.0),
              _buildFilledBox(
                icon: Icons.phone_outlined,
                controller: _receiverPhoneCtrl,
                keyboardType: TextInputType.phone,
                hint: '+91 00000 00000',
                onChanged: (_) => _syncDrop(),
              ),

              const SizedBox(height: AppSpacing.md),

              // Optional backup number. The server's receiver schema has
              // always accepted altPhone; the form never offered it.
              _buildFieldCaption('BACKUP NUMBER (OPTIONAL)'),
              const SizedBox(height: 6.0),
              _buildFilledBox(
                icon: Icons.phone_forwarded_outlined,
                controller: _receiverAltPhoneCtrl,
                keyboardType: TextInputType.phone,
                hint: 'If the first number does not answer',
                onChanged: (_) => _syncDrop(),
              ),

              const SizedBox(height: AppSpacing.md),

              _buildFieldCaption(AppLocalizations.of(context)!.houseFlatFloor),
              const SizedBox(height: 6.0),
              _buildSimpleBox(
                controller: _dropLineCtrl,
                hint: AppLocalizations.of(context)!.houseFlatHint,
                onChanged: (_) => _syncDrop(),
              ),
              const SizedBox(height: 4.0),
              Text(
                AppLocalizations.of(context)!.houseHelperText,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11.5,
                  color: const Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              _buildFieldCaption(AppLocalizations.of(context)!.landmarkLabel),
              const SizedBox(height: 6.0),
              _buildSimpleBox(
                controller: _dropLandmarkCtrl,
                hint: AppLocalizations.of(context)!.landmarkHint,
                onChanged: (_) => _syncDrop(),
              ),
              const SizedBox(height: 4.0),
              Text(
                AppLocalizations.of(context)!.landmarkHelperText,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11.5,
                  color: const Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              _buildFieldCaption('PINCODE (OPTIONAL)'),
              const SizedBox(height: 6.0),
              _buildSimpleBox(
                controller: _dropPincodeCtrl,
                hint: '6-digit pincode',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (_) => _syncDrop(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 3: WHAT
  Widget _buildStepWhat(BookingState state) {
    final receiverName = _receiverNameCtrl.text.trim().isNotEmpty
        ? _receiverNameCtrl.text.trim()
        : 'Tarun';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Package Type & Weight Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldCaption(
                AppLocalizations.of(context)!.packageCategoryLabel,
              ),
              const SizedBox(height: 12.0),

              // 6 Category Badges Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                  childAspectRatio: 2.2,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                        _selectedCategoryValue = _categoryValues[index];
                      });
                      _syncPackage();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              _buildFieldCaption(
                AppLocalizations.of(context)!.packageWeightLabel,
              ),
              const SizedBox(height: 6.0),
              _buildSimpleBox(
                controller: _weightCtrl,
                hint: AppLocalizations.of(context)!.weightHint,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => _syncPackage(),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Max ${_cityMaxWeightKg.toStringAsFixed(1)} KG • ${AppLocalizations.of(context)!.weightHelperText}',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11.5,
                  color: const Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              _buildFieldCaption(
                AppLocalizations.of(context)!.itemDescriptionLabel,
              ),
              const SizedBox(height: 6.0),
              _buildSimpleBox(
                controller: _descCtrl,
                hint: _packagePlaceholder,
                onChanged: (_) => _syncPackage(),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Declared value is accepted by the server's package schema
              // (0-1,000,000) and is what a dispute is settled against.
              _buildFieldCaption('DECLARED VALUE (OPTIONAL)'),
              const SizedBox(height: 6.0),
              _buildSimpleBox(
                controller: _declaredValueCtrl,
                hint: 'What is it worth, in rupees?',
                keyboardType: TextInputType.number,
                onChanged: (_) => _syncPackage(),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // 2. Doorstep Verification Security Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: Color(0xFF059669),
                size: 24.0,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verified at the doorstep',
                      style: AppTypography.bodyBold.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'We text $receiverName a code. The rider checks their name and number too before handing it over.',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12.0,
                        color: const Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // 3. Anyone at Address Checkbox
        Row(
          children: [
            Checkbox(
              value: _anyoneCanCollect,
              activeColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
              onChanged: (val) {
                setState(() => _anyoneCanCollect = val ?? false);
                // Reaches receiver.allowAlternate on the booking payload.
                _syncDrop();
              },
            ),
            Text(
              AppLocalizations.of(context)!.anyoneCanCollect,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 13.0,
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 4: PAY
  Widget _buildStepPay(BookingState state) {
    final quote = state.quote;
    final baseFare = quote?.baseFare ?? 30.00;
    final distanceFare = quote?.distanceFare ?? 0.00;
    final weightFare = quote?.weightFare ?? 0.00;
    final distanceKm = quote?.distanceKm ?? 0.00;
    final platformCharge = quote?.platformCharge ?? 0.00;
    final expressCharge = quote?.expressCharge ?? 0.00;
    final gstAmount = quote?.tax ?? 0.00;
    final gstPercent = quote?.gstPercent ?? 0.00;
    final coupon = state.appliedCoupon;
    final totalFare = state.payableTotal;
    final estimatedTime = quote?.estimatedTime.isNotEmpty == true
        ? quote!.estimatedTime
        : '30-40 minutes';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fare Breakdown Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(20.0),
          child: state.isQuoting
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF059669)),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFareRow(
                      'Base fare',
                      '₹${baseFare.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 12.0),
                    _buildFareRow(
                      'Distance · ${distanceKm.toStringAsFixed(2)} km',
                      '₹${distanceFare.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 12.0),
                    _buildFareRow(
                      'Weight',
                      '₹${weightFare.toStringAsFixed(2)}',
                    ),
                    if (platformCharge > 0) ...[
                      const SizedBox(height: 12.0),
                      _buildFareRow(
                        'Platform fee',
                        '₹${platformCharge.toStringAsFixed(2)}',
                      ),
                    ],
                    if (expressCharge > 0) ...[
                      const SizedBox(height: 12.0),
                      _buildFareRow(
                        'Express',
                        '₹${expressCharge.toStringAsFixed(2)}',
                      ),
                    ],
                    if (coupon != null) ...[
                      const SizedBox(height: 12.0),
                      _buildFareRow(
                        'Coupon (${coupon.code})',
                        '-₹${coupon.taxableDiscount.toStringAsFixed(2)}',
                      ),
                    ],
                    if ((coupon?.taxAmount ?? gstAmount) > 0) ...[
                      const SizedBox(height: 12.0),
                      _buildFareRow(
                        'GST (${(coupon != null && coupon.taxPercent > 0 ? coupon.taxPercent : gstPercent).toStringAsFixed(0)}%)',
                        '₹${(coupon?.taxAmount ?? gstAmount).toStringAsFixed(2)}',
                      ),
                    ],

                    const SizedBox(height: 14.0),

                    // Dashed divider line
                    const PerforationLine(
                      color: Color(0xFFE2E8F0),
                      dashWidth: 4.0,
                      dashGap: 4.0,
                    ),

                    const SizedBox(height: 14.0),

                    // Total Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL',
                          style: AppTypography.monoLabel.copyWith(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          '₹${totalFare.toStringAsFixed(2)}',
                          style: AppTypography.monoData.copyWith(
                            fontSize: 24.0,
                            fontWeight: FontWeight.w800,
                            color: totalFare > 0
                                ? const Color(0xFF059669)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14.0),

                    // Arriving in about XX minutes
                    Text(
                      'Arriving in about $estimatedTime',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),

        if (quote != null && !state.isQuoting) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildCouponCard(state),
        ],

        const SizedBox(height: AppSpacing.lg),

        // Delivery speed. The city fare service prices `express` with a
        // configured surcharge; only the outstation flow used to offer it.
        Row(
          children: [
            _buildSpeedButton('normal', 'Standard', state),
            const SizedBox(width: 10.0),
            _buildSpeedButton(
              'express',
              _expressCharge > 0
                  ? 'Express +₹${_expressCharge.toStringAsFixed(0)}'
                  : 'Express',
              state,
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        // Payment Method Selector
        Row(
          children: [
            _buildPaymentMethodButton(
              'UPI',
              AppLocalizations.of(context)!.upiPayment,
            ),
            const SizedBox(width: 10.0),
            _buildPaymentMethodButton(
              'CARD',
              AppLocalizations.of(context)!.cardPayment,
            ),
            const SizedBox(width: 10.0),
            _buildPaymentMethodButton(
              'COD',
              AppLocalizations.of(context)!.codPayment,
            ),
          ],
        ),


        // A booking that exists but was never paid for. The backend keeps it
        // at REQUESTED and dispatches nobody until the signature verifies, so
        // the customer needs an explicit way back into checkout.
        if (state.canRetryPayment) ...[
          const SizedBox(height: 14.0),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: const Color(0xFFFDBA74)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.paymentMessage ??
                      'This booking is waiting for payment.',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 12.5,
                    color: const Color(0xFF9A3412),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10.0),
                SizedBox(
                  width: double.infinity,
                  height: 42.0,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    onPressed: () => context.read<BookingBloc>().add(
                          BookingPaymentRetryRequested(),
                        ),
                    child: const Text(
                      'RETRY PAYMENT',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (_selectedPaymentMethod == 'COD') ...[
          const SizedBox(height: 14.0),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              'The rider collects the fare from you at pickup.',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 12.0,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Same coupon flow as the web booking: type a code or tap an offer →
  /// `POST /city-parcel/coupon/validate`; the applied code rides on create.
  Widget _buildCouponCard(BookingState state) {
    final applied = state.appliedCoupon;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFieldCaption('COUPON'),
              if (applied != null)
                GestureDetector(
                  onTap: () {
                    _couponCtrl.clear();
                    context.read<BookingBloc>().add(BookingCouponRemoved());
                  },
                  child: Text(
                    'REMOVE',
                    style: AppTypography.monoLabel.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFDC2626),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10.0),
          if (applied != null)
            Text(
              '${applied.code} applied — you saved ₹${applied.discountAmount.toStringAsFixed(2)}',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 13.0,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF047857),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _buildSimpleBox(
                    controller: _couponCtrl,
                    hint: 'Enter coupon code',
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(40),
                      TextInputFormatter.withFunction(
                        (oldValue, newValue) =>
                            newValue.copyWith(text: newValue.text.toUpperCase()),
                      ),
                    ],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10.0),
                SizedBox(
                  height: 44.0,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF10B981)),
                      backgroundColor: const Color(0xFFECFDF5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: _couponCtrl.text.trim().isEmpty ||
                            state.isApplyingCoupon
                        ? null
                        : () => context.read<BookingBloc>().add(
                              BookingCouponApplyRequested(_couponCtrl.text),
                            ),
                    child: state.isApplyingCoupon
                        ? const SizedBox(
                            width: 16.0,
                            height: 16.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              color: Color(0xFF059669),
                            ),
                          )
                        : const Text(
                            'APPLY',
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                  ),
                ),
              ],
            ),
            if (state.couponError != null) ...[
              const SizedBox(height: 6.0),
              Text(
                state.couponError!,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 12.0,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ],
            if (state.availableCoupons.isNotEmpty) ...[
              const SizedBox(height: 10.0),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: state.availableCoupons.map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          _couponCtrl.text = c.code;
                          context.read<BookingBloc>().add(
                                BookingCouponApplyRequested(c.code),
                              );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 7.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(color: const Color(0xFF10B981)),
                          ),
                          child: Text(
                            c.label,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSpeedButton(String key, String label, BookingState state) {
    final isSelected = state.deliverySpeed == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<BookingBloc>().add(
              BookingDeliverySpeedSelected(key),
            ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.0,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodButton(String key, String label) {
    final isSelected = _selectedPaymentMethod == key;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPaymentMethod = key);
          context.read<BookingBloc>().add(BookingPaymentMethodSelected(key));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF10B981)
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.0,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFareRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 13.5,
            color: const Color(0xFF475569),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: AppTypography.monoDataSmall.copyWith(
            fontSize: 13.5,
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldCaption(String text) {
    return Text(
      text,
      style: AppTypography.monoLabel.copyWith(
        fontSize: 10.0,
        color: const Color(0xFF64748B),
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildFilledBox({
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 18.0, color: const Color(0xFF64748B)),
          const SizedBox(width: 8.0),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: keyboardType == TextInputType.phone
                  ? [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ]
                  : null,
              onChanged: onChanged,
              style: AppTypography.bodyRegular.copyWith(
                color: const Color(0xFF0F172A),
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText:
                    keyboardType == TextInputType.phone &&
                        hint.startsWith('+91')
                    ? '00000 00000'
                    : hint,
                hintStyle: AppTypography.bodyRegular.copyWith(
                  color: const Color(0xFF94A3B8),
                  fontSize: 14.0,
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

  Widget _buildSimpleBox({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 2.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: AppTypography.bodyRegular.copyWith(
          color: const Color(0xFF0F172A),
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
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

  bool _canProceedStep(BookingState state) {
    switch (state.currentStep) {
      case 0:
        final phone = _senderPhoneCtrl.text.replaceAll(RegExp(r'\D'), '');
        // Coordinates are mandatory in the server's address schema, so a
        // typed-but-unresolved address cannot be submitted.
        return _senderNameCtrl.text.trim().isNotEmpty &&
            phone.length >= 10 &&
            _pickupAddrCtrl.text.trim().length >= 5 &&
            _pickupLat != 0.0 &&
            _pickupLng != 0.0 &&
            _isValidPincode(_pickupPincodeCtrl.text);
      case 1:
        final phone = _receiverPhoneCtrl.text.replaceAll(RegExp(r'\D'), '');
        final isSame = _isSameLocation(
          pickupAddr: _pickupAddrCtrl.text,
          pickupLat: _pickupLat,
          pickupLng: _pickupLng,
          dropAddr: _dropAddrCtrl.text,
          dropLat: _dropLat,
          dropLng: _dropLng,
        );
        return _receiverNameCtrl.text.trim().isNotEmpty &&
            phone.length >= 10 &&
            _dropAddrCtrl.text.trim().length >= 5 &&
            _dropLat != 0.0 &&
            _dropLng != 0.0 &&
            _isValidPincode(_dropPincodeCtrl.text) &&
            !isSame;
      case 2:
        // The server rejects anything under 0.1 kg or over its configured
        // maximum, so the same bounds are enforced here.
        final weight = double.tryParse(_weightCtrl.text.trim()) ?? 0.0;
        return _selectedCategory.isNotEmpty &&
            weight >= 0.1 &&
            weight <= _cityMaxWeightKg;
      case 3:
        final fare = state.payableTotal;
        return _cityDeliveryEnabled &&
            _selectedPaymentMethod.isNotEmpty &&
            fare > 0 &&
            !state.isQuoting &&
            !state.isPaymentInFlight;
      default:
        return false;
    }
  }

  void _showValidationError(int step) {
    final l10n = AppLocalizations.of(context)!;

    switch (step) {
      case 0:
        if (_pickupAddrCtrl.text.trim().isEmpty) {
          AppSnackBar.showError(context, l10n.bookingPickupAddress);
        } else if (_pickupLat == 0.0 || _pickupLng == 0.0) {
          AppSnackBar.showError(
            context,
            'Pick the pickup point on the map so the rider can find it',
          );
        } else if (!_isValidPincode(_pickupPincodeCtrl.text)) {
          AppSnackBar.showError(context, 'Enter a valid 6-digit pickup pincode.');
        } else if (_senderNameCtrl.text.trim().isEmpty) {
          AppSnackBar.showError(context, l10n.bookingEnterSenderName);
        } else {
          AppSnackBar.showError(context, l10n.bookingEnterSenderPhone);
        }
        break;
      case 1:
        final isSame = _isSameLocation(
          pickupAddr: _pickupAddrCtrl.text,
          pickupLat: _pickupLat,
          pickupLng: _pickupLng,
          dropAddr: _dropAddrCtrl.text,
          dropLat: _dropLat,
          dropLng: _dropLng,
        );
        if (_dropAddrCtrl.text.trim().isEmpty) {
          AppSnackBar.showError(context, l10n.bookingDropAddress);
        } else if (_dropLat == 0.0 || _dropLng == 0.0) {
          AppSnackBar.showError(
            context,
            'Pick the drop point on the map so the rider can find it',
          );
        } else if (isSame) {
          AppSnackBar.showError(
            context,
            'Pickup and drop look like the same place',
          );
        } else if (!_isValidPincode(_dropPincodeCtrl.text)) {
          AppSnackBar.showError(context, 'Enter a valid 6-digit drop pincode.');
        } else if (_receiverNameCtrl.text.trim().isEmpty) {
          AppSnackBar.showError(context, l10n.bookingEnterReceiverName);
        } else {
          AppSnackBar.showError(context, l10n.bookingEnterReceiverPhone);
        }
        break;
      case 2:
        final weight = double.tryParse(_weightCtrl.text.trim()) ?? 0.0;
        if (weight < 0.1) {
          AppSnackBar.showError(context, l10n.bookingParcelWeight);
        } else if (weight > _cityMaxWeightKg) {
          AppSnackBar.showError(
            context,
            'That is heavier than we can carry on a bike '
            '(max ${_cityMaxWeightKg.toStringAsFixed(1)} kg)',
          );
        } else {
          AppSnackBar.showError(context, l10n.selectPackageCategoryTitle);
        }
        break;
      case 3:
        if (_selectedPaymentMethod.isEmpty) {
          AppSnackBar.showError(context, l10n.bookingPaymentMethod);
        } else {
          AppSnackBar.showError(context, l10n.pricing);
        }
        break;
    }
  }

  String _localizedBookingError(String message, AppLocalizations l10n) {
    switch (message) {
      case "Couldn't price this delivery":
      case "Couldn't place the parcel booking":
        return l10n.error;
      default:
        return message;
    }
  }

  Widget _buildBottomAction(BookingState state) {
    final isLastStep = state.currentStep == 3;
    final fare = state.payableTotal;
    final isValid = _canProceedStep(state);

    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50.0,
          child: Stack(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.isPlacing
                      ? const Color(0xFFA7F3D0)
                      : (isValid
                            ? const Color(0xFF059669)
                            : const Color(0xFF059669).withValues(alpha: 0.4)),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: state.isPlacing
                    ? null
                    : () {
                        if (!isValid) {
                          _showValidationError(state.currentStep);
                          return;
                        }
                        if (!isLastStep) {
                          context.read<BookingBloc>().add(
                            BookingStepChanged(state.currentStep + 1),
                          );
                        } else {
                          context.read<BookingBloc>().add(
                            BookingSubmitRequested(),
                          );
                        }
                      },
                child: state.isPlacing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18.0,
                            height: 18.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          Text(
                            AppLocalizations.of(context)!.submitting
                                .toUpperCase(),
                            style: AppTypography.monoLabel.copyWith(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastStep
                                ? (fare > 0
                                      ? AppLocalizations.of(context)!
                                            .confirmAndPay(
                                              '₹${fare.toStringAsFixed(2)}',
                                            )
                                            .toUpperCase()
                                      : AppLocalizations.of(context)!
                                            .bookingConfirmOrder
                                            .toUpperCase())
                                : AppLocalizations.of(context)!.continueText
                                      .toUpperCase(),
                            style: AppTypography.monoLabel.copyWith(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (!isLastStep) ...[
                            const SizedBox(width: 8.0),
                            const Icon(
                              Icons.arrow_forward,
                              size: 16.0,
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
              ),
              if (!isValid && !state.isPlacing)
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.0),
                      onTap: () => _showValidationError(state.currentStep),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
