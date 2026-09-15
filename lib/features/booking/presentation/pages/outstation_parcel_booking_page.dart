import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sungguard/l10n/app_localizations.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/services/razorpay_checkout_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/dashed_border_painter.dart';
import '../../../../core/widgets/ink_barcode.dart';
import '../../../../core/widgets/perforation_line.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/models/booking_creation_result.dart';
import '../../data/models/coupon_models.dart';
import '../widgets/outstation_map_picker_dialog.dart';

const List<Map<String, dynamic>> _kDestinationCities = [
  {'name': 'Mumbai', 'lat': 19.076, 'lng': 72.8777},
  {'name': 'Delhi', 'lat': 28.6139, 'lng': 77.209},
  {'name': 'Bengaluru', 'lat': 12.9716, 'lng': 77.5946},
  {'name': 'Hyderabad', 'lat': 17.385, 'lng': 78.4867},
  {'name': 'Chennai', 'lat': 13.0827, 'lng': 80.2707},
  {'name': 'Kolkata', 'lat': 22.5726, 'lng': 88.3639},
  {'name': 'Pune', 'lat': 18.5204, 'lng': 73.8567},
  {'name': 'Ahmedabad', 'lat': 23.0225, 'lng': 72.5714},
  {'name': 'Jaipur', 'lat': 26.9124, 'lng': 75.7873},
  {'name': 'Surat', 'lat': 21.1702, 'lng': 72.8311},
  {'name': 'Lucknow', 'lat': 26.8467, 'lng': 80.9462},
  {'name': 'Chandigarh', 'lat': 30.7333, 'lng': 76.7794},
  {'name': 'Indore', 'lat': 22.7196, 'lng': 75.8577},
  {'name': 'Bhopal', 'lat': 23.2599, 'lng': 77.4126},
  {'name': 'Nagpur', 'lat': 21.1458, 'lng': 79.0882},
  {'name': 'Patna', 'lat': 25.5941, 'lng': 85.1376},
  {'name': 'Kochi', 'lat': 9.9312, 'lng': 76.2673},
  {'name': 'Coimbatore', 'lat': 11.0168, 'lng': 76.9558},
  {'name': 'Visakhapatnam', 'lat': 17.6868, 'lng': 83.2185},
  {'name': 'Other', 'lat': 20.5937, 'lng': 78.9629},
];

class OutstationParcelBookingPage extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(String parcelId)? onBookingSuccess;

  const OutstationParcelBookingPage({
    super.key,
    this.onBack,
    this.onBookingSuccess,
  });

  @override
  State<OutstationParcelBookingPage> createState() =>
      _OutstationParcelBookingPageState();
}

class _OutstationParcelBookingPageState
    extends State<OutstationParcelBookingPage> {
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
    if (widget.onBookingSuccess != null) {
      widget.onBookingSuccess!(parcelId);
    } else {
      context.pushReplacement('/parcel/outstation/track/$parcelId');
    }
  }

  final RazorpayCheckoutService _checkout = RazorpayCheckoutService();

  /// Destination cities offered in the picker.
  ///
  /// Seeded from the built-in list so the screen works offline, then extended
  /// with the cities the backend actually operates warehouses in
  /// (GET /warehouse/active), which was never consulted. The static entries
  /// stay because that endpoint returns warehouses, not a curated destination
  /// list — dropping them would shrink what a customer can book.
  List<Map<String, dynamic>> _destinationCities =
      List<Map<String, dynamic>>.from(_kDestinationCities);

  Future<void> _loadServiceableCities() async {
    try {
      final res = await ApiClient.createDefault().get(
        ApiEndpoints.warehousesActive,
      );
      // This endpoint answers with `results` (plural), which ApiClient does not
      // unwrap — it only unwraps `result` and `data`. The other spellings are
      // kept as a defensive net.
      final raw = (res is Map)
          ? (res['results'] ??
              res['warehouses'] ??
              res['items'] ??
              res['result'] ??
              res['data'])
          : res;
      if (raw is! List) return;

      final discovered = <Map<String, dynamic>>[];
      for (final entry in raw.whereType<Map>()) {
        final city = entry['city']?.toString().trim() ?? '';
        final lat = (entry['lat'] as num?)?.toDouble();
        final lng = (entry['lng'] as num?)?.toDouble();
        if (city.isEmpty || lat == null || lng == null) continue;
        discovered.add({'name': city, 'lat': lat, 'lng': lng});
      }
      if (discovered.isEmpty || !mounted) return;

      // Merge on city name, preferring the server's coordinates, and keep
      // "Other" last so it stays the fallback option.
      final merged = <String, Map<String, dynamic>>{};
      for (final c in _kDestinationCities) {
        merged[c['name'] as String] = Map<String, dynamic>.from(c);
      }
      for (final c in discovered) {
        merged[c['name'] as String] = c;
      }
      final other = merged.remove('Other');
      final ordered = merged.values.toList()
        ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      if (other != null) ordered.add(other);

      setState(() => _destinationCities = ordered);
    } catch (_) {
      // The static list stands.
    }
  }

  int _step = 0; // 0: From, 1: To, 2: What, 3: Pay
  int _furthestStep = 0;

  // Step 0: FROM (Collection Point)
  final _senderNameCtrl = TextEditingController();
  final _senderPhoneCtrl = TextEditingController();
  final _pickupAddressCtrl = TextEditingController();
  final _pickupLandmarkCtrl = TextEditingController();
  final _pickupCityCtrl = TextEditingController();
  final _pickupStateCtrl = TextEditingController();
  final _pickupPincodeCtrl = TextEditingController();
  double? _pickupLat;
  double? _pickupLng;
  Map<String, dynamic>? _nearestWarehouse;
  bool _reviewsExpanded = false;
  Map<String, dynamic>? _fareEstimation;
  Timer? _fareDebounceTimer;
  List<Map<String, dynamic>> _reviewItems = [];
  double _avgRating = 0.0;
  int _reviewCount = 0;

  final Map<String, String?> _fieldErrors = {};

  String? _validateSenderName(String val) {
    final trimmed = val.trim();
    if (trimmed.isEmpty) return 'Please enter sender full name';
    if (trimmed.length < 2) return 'Sender name must be at least 2 characters';
    if (trimmed.length > 80) return 'Sender name must be under 80 characters';
    if (RegExp(r'\d').hasMatch(trimmed)) {
      return 'Sender name cannot contain numbers';
    }
    return null;
  }

  String? _validateSenderPhone(String val) {
    final cleaned = val.trim().replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.isEmpty) return 'Please enter 10-digit sender phone number';
    if (cleaned.length != 10) return 'Phone number must be exactly 10 digits';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return 'Enter a valid 10-digit mobile number (starts with 6-9)';
    }
    return null;
  }

  String? _validatePickupAddress(String val) {
    final trimmed = val.trim();
    if (trimmed.isEmpty) return 'Please enter house/flat/street address';
    if (trimmed.length < 5) return 'Pickup address must be at least 5 characters long';
    if (trimmed.length > 500) return 'Pickup address must be under 500 characters';
    return null;
  }

  String? _validateLandmark(String val) {
    final trimmed = val.trim();
    if (trimmed.isNotEmpty && trimmed.length > 100) {
      return 'Landmark must be under 100 characters';
    }
    return null;
  }

  String? _validateCity(String val) {
    final trimmed = val.trim();
    if (trimmed.isEmpty) return 'Please enter city name';
    if (trimmed.length < 2) return 'City name must be at least 2 characters';
    if (RegExp(r'\d').hasMatch(trimmed)) {
      return 'City name cannot contain numbers';
    }
    return null;
  }

  String? _validateState(String val) {
    final trimmed = val.trim();
    if (trimmed.isEmpty) return 'Please enter state name';
    if (trimmed.length < 2) return 'State name must be at least 2 characters';
    if (RegExp(r'\d').hasMatch(trimmed)) {
      return 'State name cannot contain numbers';
    }
    return null;
  }

  String? _validatePincode(String val) {
    final cleaned = val.trim().replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) return 'Please enter 6-digit pincode';
    if (!RegExp(r'^[1-9]\d{5}$').hasMatch(cleaned)) {
      return 'Enter a valid 6-digit Indian pincode';
    }
    return null;
  }

  String? _validateCustomCourier(String val) {
    final trimmed = val.trim();
    if (trimmed.isEmpty) return 'Please enter courier company name';
    if (trimmed.length < 2) return 'Courier company name must be at least 2 characters';
    if (trimmed.length > 100) return 'Courier company name must be under 100 characters';
    return null;
  }

  String? _validateCustomDays(String val) {
    final trimmed = val.trim();
    if (trimmed.isEmpty) return 'Please enter booking duration in days';
    final days = int.tryParse(trimmed);
    if (days == null || days < 2 || days > 30) {
      return 'Custom duration must be between 2 and 30 days';
    }
    return null;
  }

  String? _validateWeight(String val) {
    final trimmed = val.trim();
    if (trimmed.isEmpty) return 'Please enter package weight';
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed <= 0) {
      return 'Please enter a valid weight';
    }
    final weightInKg = _weightUnit == 'gm' ? parsed / 1000.0 : parsed;
    if (weightInKg <= 0 || weightInKg > _maxWeightKg) {
      return 'Weight must be up to ${_maxWeightKg.toStringAsFixed(1)} KG';
    }
    return null;
  }

  String? _validateDescription(String val) {
    final trimmed = val.trim();
    if (trimmed.length > 500) {
      return 'Package description must be under 500 characters';
    }
    return null;
  }

  // Step 1: TO (Destination, Duration & Courier)
  List<Map<String, dynamic>> _courierCompanies = [];
  String _selectedCourierId = '';
  bool _isCourierDropdownOpen = false;

  String _destinationCity = '';
  bool _isCityDropdownOpen = false;

  final _customCourierCtrl = TextEditingController();
  bool _customCourierSaved = false;

  String _bookingDurationMode =
      'one_day'; // 'one_day' | 'custom_days' | 'by_date'
  final _customDaysCtrl = TextEditingController(text: '7');
  DateTime _preferredPickupDate = DateTime.now();

  // Step 2: WHAT (Weight, Speed, Segment & Category)
  final _weightCtrl = TextEditingController(text: '0.2');
  String _weightUnit = 'kg'; // 'kg' | 'gm'
  double _maxWeightKg = 1.0;
  String _deliverySpeed = 'normal'; // 'normal' | 'express'
  double _expressChargeConfig = 90.0;

  String _packageSegment = 'personal'; // 'personal' | 'business'
  String _packageCategory = 'Gift';
  // API-driven values — kept internal, UI still shows labels
  String _selectedPackageTypeValue = 'other';
  String _selectedPackageCategoryValue = 'personal_gift';
  List<Map<String, dynamic>> _apiPackageTypes = [];
  List<Map<String, dynamic>> _apiPackageCategories = [];
  final _descriptionCtrl = TextEditingController();
  String _packageDescriptionPlaceholder =
      'E.g. keys, critical document papers...';

  List<String> _personalCategories = [
    'Gift',
    'Personal Documents',
    'Clothing',
    'Electronics',
    'Books & Media',
    'Other Personal',
  ];

  List<String> _businessCategories = [
    'Invoice / Bills',
    'Product Samples',
    'Business Documents',
    'Commercial Goods',
    'Spare Parts',
    'Other Business',
  ];

  // Step 3: PAY (Payment & Fare Breakdown)
  String _paymentMethod = 'COD'; // 'COD' | 'UPI'
  bool _isEstimating = false;
  bool _isSubmitting = false;
  double _totalFare = 0.0;
  double _baseFare = 0.0;
  double _distanceFare = 0.0;
  double _perKmCharge = 0.0;
  double _weightFare = 0.0;
  double _platformCharge = 0.0;
  double _expressCharge = 0.0;
  double _distanceKm = 0.0;
  double _gstAmount = 0.0;
  double _gstPercent = 0.0;

  // Coupons — same flow as the web outstation booking.
  final _couponCtrl = TextEditingController();
  List<AvailableCoupon> _availableCoupons = const [];
  AppliedCoupon? _appliedCoupon;
  bool _applyingCoupon = false;
  String? _couponError;

  /// What the customer is charged: the coupon's `payableFare`, else `fare`.
  double get _payableFare => _appliedCoupon?.payableFare ?? _totalFare;

  String _sanitizePersonName(String raw) {
    var cleaned = raw.replaceAll(RegExp(r'[0-9]'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    // Keep only letters, marks, spaces, .'-
    cleaned = cleaned.replaceAll(RegExp(r"[^\p{L}\p{M}\s.'-]", unicode: true), '').trim();
    if (cleaned.length < 2) return 'Customer';
    if (cleaned.length > 80) cleaned = cleaned.substring(0, 80).trim();
    // must contain at least one letter
    if (!RegExp(r'\p{L}', unicode: true).hasMatch(cleaned)) return 'Customer';
    // Fallback to Title Case
    return cleaned;
  }

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      final rawName = user.name.trim().isNotEmpty ? user.name.trim() : 'Customer';
      _senderNameCtrl.text = _sanitizePersonName(rawName);
      _senderPhoneCtrl.text = user.phone;
    }
    // sanitize on edit so digit never reaches payload
    _senderNameCtrl.addListener(() {
      final t = _senderNameCtrl.text;
      final sanitized = t.replaceAll(RegExp(r'[0-9]'), '');
      if (sanitized != t) {
        _senderNameCtrl.value = TextEditingValue(
          text: sanitized,
          selection: TextSelection.collapsed(offset: sanitized.length.clamp(0, sanitized.length)),
        );
      }
    });
    _weightCtrl.addListener(_calculateFare);
    _loadBookingConfig();
    _loadReviews();
    _loadServiceableCities();
  }

  Future<void> _loadReviews() async {
    try {
      final client = ApiClient.createDefault();
      final res = await client.get(
        ApiEndpoints.outstationParcelReviews,
        queryParameters: {'limit': 50},
      );
      final result = (res is Map)
          ? (res['result'] ?? res['data'] ?? res)
          : null;
      if (result is Map) {
        final items =
            (result['items'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .toList() ??
            [];
        setState(() {
          _reviewItems = items;
          _avgRating = (result['avgRating'] as num?)?.toDouble() ?? 0.0;
          _reviewCount =
              (result['reviewCount'] as num?)?.toInt() ?? items.length;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _fareDebounceTimer?.cancel();
    _weightCtrl.removeListener(_calculateFare);
    _senderNameCtrl.dispose();
    _senderPhoneCtrl.dispose();
    _pickupAddressCtrl.dispose();
    _pickupLandmarkCtrl.dispose();
    _pickupCityCtrl.dispose();
    _pickupStateCtrl.dispose();
    _pickupPincodeCtrl.dispose();
    _customCourierCtrl.dispose();
    _customDaysCtrl.dispose();
    _weightCtrl.dispose();
    _descriptionCtrl.dispose();
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBookingConfig() async {
    try {
      final client = ApiClient.createDefault();
      final res = await client.get(ApiEndpoints.outstationParcelBookingConfig);
      final data = (res is Map) ? (res['result'] ?? res['data'] ?? res) : null;
      if (data is Map) {
        // --- packageTypes & categories are API-driven (no static fallthrough in UI) ---
        final apiTypes = (data['packageTypes'] as List?) ?? [];
        final apiCats = (data['packageCategories'] as List?) ?? [];
        final parsedTypes = apiTypes.whereType<Map>().map<Map<String, dynamic>>((e) {
          final m = Map<String, dynamic>.from(e);
          return <String, dynamic>{
            'value': m['value']?.toString() ?? '',
            'label': m['label']?.toString() ?? m['value']?.toString() ?? '',
            'isActive': m['isActive'] != false,
          };
        }).where((e) => e['value'].toString().isNotEmpty).toList();
        final parsedCats = apiCats.whereType<Map>().map<Map<String, dynamic>>((e) {
          final m = Map<String, dynamic>.from(e);
          return <String, dynamic>{
            'value': m['value']?.toString() ?? '',
            'label': m['label']?.toString() ?? '',
            'segment': (m['segment']?.toString() == 'business' ? 'business' : 'personal'),
            'isActive': m['isActive'] != false,
          };
        }).where((e) => e['label'].toString().isNotEmpty).toList();

        final couriers = data['courierCompanies'];
        final parsedCouriers = (couriers is List)
            ? couriers.map<Map<String, dynamic>>((c) {
                final map = c is Map ? c : <String, dynamic>{};
                final isOther = map['isOther'] == true;
                return <String, dynamic>{
                  'id': map['id']?.toString() ?? map['_id']?.toString() ?? '',
                  'name': map['name']?.toString() ?? '',
                  'platformCharge':
                      (map['platformCharge'] as num?)?.toDouble() ?? 0.0,
                  'companyCharge':
                      (map['companyCharge'] as num?)?.toDouble() ?? 0.0,
                  'isOther': isOther,
                };
              }).toList()
            : <Map<String, dynamic>>[];

        setState(() {
          if (parsedTypes.isNotEmpty) {
            _apiPackageTypes = parsedTypes;
            final firstActive = parsedTypes.firstWhere(
              (e) => e['isActive'] == true,
              orElse: () => parsedTypes.first,
            );
            _selectedPackageTypeValue = firstActive['value'] as String;
            if (_selectedPackageTypeValue.isEmpty) _selectedPackageTypeValue = 'other';
          }
          if (parsedCats.isNotEmpty) {
            _apiPackageCategories = parsedCats;
            final personal = parsedCats
                .where((e) => e['segment'] == 'personal' && e['isActive'] == true)
                .map((e) => e['label'] as String)
                .toList();
            final business = parsedCats
                .where((e) => e['segment'] == 'business' && e['isActive'] == true)
                .map((e) => e['label'] as String)
                .toList();
            if (personal.isNotEmpty) _personalCategories = personal;
            if (business.isNotEmpty) _businessCategories = business;
            // keep selected category in sync with API
            final curLabels = _packageSegment == 'personal' ? _personalCategories : _businessCategories;
            if (!curLabels.contains(_packageCategory) && curLabels.isNotEmpty) {
              _packageCategory = curLabels.first;
            }
            // also sync value
            final catObj = parsedCats.firstWhere(
              (e) => e['label'] == _packageCategory,
              orElse: () => parsedCats.first,
            );
            _selectedPackageCategoryValue = catObj['value'] as String;
          }
          _courierCompanies = parsedCouriers;
          // Step 3 requirement: Courier selection must default to neutral placeholder ("Select a courier company")
          _selectedCourierId = '';
          _expressChargeConfig =
              (data['expressCharge'] as num?)?.toDouble() ?? 90.0;
          _maxWeightKg = (data['maxWeightKg'] as num?)?.toDouble() ?? 1.0;
          if (data['packageDescriptionPlaceholder'] != null) {
            _packageDescriptionPlaceholder =
                data['packageDescriptionPlaceholder'].toString();
          }
        });
        _calculateFare();
      }
    } catch (_) {}
  }

  double get _effectiveWeightKg {
    final raw = double.tryParse(_weightCtrl.text.trim()) ?? 0.2;
    if (_weightUnit == 'gm') {
      return (((raw / 1000.0) * 1000).round()) / 1000.0;
    }
    return ((raw * 1000).round()) / 1000.0;
  }

  Map<String, dynamic>? get _selectedCourier {
    if (_selectedCourierId.isEmpty || _courierCompanies.isEmpty) {
      return null;
    }
    for (final c in _courierCompanies) {
      if (c['id'] == _selectedCourierId || c['name'] == _selectedCourierId) {
        return c;
      }
    }
    return null;
  }

  bool get _isOtherCourier => _selectedCourier?['isOther'] == true;

  double get _formCompletionRatio {
    int score = 0;
    const total = 10;
    if (_senderNameCtrl.text.trim().isNotEmpty) score++;
    if (_senderPhoneCtrl.text.trim().isNotEmpty) score++;
    if (_pickupAddressCtrl.text.trim().isNotEmpty) score++;
    if (_pickupCityCtrl.text.trim().isNotEmpty) score++;
    if (_pickupPincodeCtrl.text.trim().isNotEmpty) score++;
    if (_pickupLat != null) score++;
    if (_destinationCity.isNotEmpty) score++;
    if (!_isOtherCourier || _customCourierSaved) score++;
    if (_effectiveWeightKg > 0 && _effectiveWeightKg <= _maxWeightKg) score++;
    if (_step >= 2) score++;
    return (score / total).clamp(0.1, 1.0);
  }

  Map<String, dynamic> _resolveBookingDurationParams() {
    if (_bookingDurationMode == 'one_day') {
      return {
        'pickupWindow': 'today',
        'pickupWindowDays': 0,
        'preferredPickupDate': DateTime.now()
            .toIso8601String()
            .split('T')
            .first,
      };
    }
    if (_bookingDurationMode == 'custom_days') {
      final days = int.tryParse(_customDaysCtrl.text.trim()) ?? 7;
      final clamped = days.clamp(2, 30);
      final endDate = DateTime.now().add(Duration(days: clamped));
      return {
        'pickupWindow': 'custom_days',
        'pickupWindowDays': clamped,
        'preferredPickupDate': endDate.toIso8601String().split('T').first,
      };
    }
    return {
      'pickupWindow': 'specific',
      'pickupWindowDays': null,
      'preferredPickupDate': _preferredPickupDate
          .toIso8601String()
          .split('T')
          .first,
    };
  }

  Future<void> _fetchNearestWarehouse(double lat, double lng) async {
    try {
      final client = ApiClient.createDefault();
      final res = await client.get(
        ApiEndpoints.outstationParcelNearestWarehouse,
        queryParameters: {'lat': lat, 'lng': lng},
      );
      final result = (res is Map)
          ? (res['result'] ?? res['data'] ?? res['warehouse'] ?? res)
          : null;
      if (result is Map && mounted) {
        setState(() {
          _nearestWarehouse = Map<String, dynamic>.from(result);
        });
      }
    } catch (_) {}
  }

  /// Body shared by `POST /parcel/calculate-fare` and `/parcel/coupon/validate`.
  Map<String, dynamic> _buildFarePayload() {
    final duration = _resolveBookingDurationParams();
    final courier = _selectedCourier;
    final courierName = _isOtherCourier
        ? (_customCourierCtrl.text.trim().isNotEmpty
              ? _customCourierCtrl.text.trim()
              : null)
        : courier?['name'];
    final courierId = courier?['id'];

    return <String, dynamic>{
      'pickupLat': _pickupLat,
      'pickupLng': _pickupLng,
      'parcelType': 'outstation',
      'weight': _effectiveWeightKg,
      'pickupWindow': duration['pickupWindow'],
      'pickupWindowDays': duration['pickupWindowDays'],
      'preferredPickupDate': duration['preferredPickupDate'],
      'deliverySpeed': _deliverySpeed,
      if (courierId != null && courierId.toString().isNotEmpty)
        'courierCompanyId': courierId,
      if (courierName != null && courierName.toString().isNotEmpty)
        'courierCompany': courierName,
    };
  }

  /// `GET /parcel/coupons/available?fare=&parcelType=outstation`.
  Future<void> _loadCoupons() async {
    if (_totalFare <= 0) return;
    try {
      final res = await ApiClient.createDefault().get(
        ApiEndpoints.outstationParcelCouponsAvailable,
        queryParameters: {'fare': _totalFare, 'parcelType': 'outstation'},
      );
      if (mounted) setState(() => _availableCoupons = AvailableCoupon.listFrom(res));
    } catch (_) {
      if (mounted) setState(() => _availableCoupons = const []);
    }
  }

  /// `POST /parcel/coupon/validate` — the server re-prices, never trusts ours.
  Future<void> _applyCoupon(String code) async {
    final value = code.trim().toUpperCase();
    if (value.isEmpty || _pickupLat == null || _applyingCoupon) return;
    setState(() {
      _applyingCoupon = true;
      _couponError = null;
    });
    try {
      final res = await ApiClient.createDefault().post(
        ApiEndpoints.outstationParcelCouponValidate,
        data: {..._buildFarePayload(), 'couponCode': value},
      );
      if (!mounted) return;
      setState(() {
        _appliedCoupon = AppliedCoupon.fromJson(res);
        _couponCtrl.text = value;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _appliedCoupon = null;
        _couponError = (e is ApiException && e.message.isNotEmpty)
            ? e.message
            : "Couldn't apply this coupon";
      });
    } finally {
      if (mounted) setState(() => _applyingCoupon = false);
    }
  }

  void _calculateFare() {
    _fareDebounceTimer?.cancel();
    _fareDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      if (_isOtherCourier && !_customCourierSaved) {
        setState(() {
          _fareEstimation = null;
          _totalFare = 0.0;
        });
        return;
      }

      final customDays = int.tryParse(_customDaysCtrl.text.trim()) ?? 7;
      if (_bookingDurationMode == 'custom_days' &&
          (customDays < 2 || customDays > 30)) {
        setState(() {
          _fareEstimation = null;
          _totalFare = 0.0;
        });
        return;
      }

      if (_pickupLat != null && _pickupLng != null && _effectiveWeightKg > 0) {
        setState(() => _isEstimating = true);
        try {
          final client = ApiClient.createDefault();
          final res = await client.post(
            ApiEndpoints.outstationParcelCalculateFare,
            data: _buildFarePayload(),
          );

          if (!mounted) return;

          final result = (res is Map)
              ? (res['result'] ?? res['data'] ?? res)
              : null;
          if (result is Map) {
            setState(() {
              _fareEstimation = Map<String, dynamic>.from(result);
              _totalFare = (result['fare'] as num?)?.toDouble() ?? 0.0;
              _baseFare = (result['baseFare'] as num?)?.toDouble() ?? 0.0;
              _distanceFare =
                  (result['distanceFare'] as num?)?.toDouble() ?? 0.0;
              _perKmCharge = (result['perKmCharge'] as num?)?.toDouble() ?? 0.0;
              _weightFare = (result['weightFare'] as num?)?.toDouble() ?? 0.0;
              _platformCharge =
                  (result['platformCharge'] as num?)?.toDouble() ??
                  (result['courierCharge'] as num?)?.toDouble() ??
                  0.0;
              _expressCharge =
                  (result['expressCharge'] as num?)?.toDouble() ?? 0.0;
              _distanceKm = (result['distance'] as num?)?.toDouble() ?? 0.0;
              _gstAmount = (result['gstAmount'] as num?)?.toDouble() ?? 0.0;
              _gstPercent = (result['gstPercent'] as num?)?.toDouble() ?? 0.0;
              // A re-priced trip invalidates a coupon applied to the old fare.
              _appliedCoupon = null;
              _couponError = null;
            });
            _loadCoupons();
          }
        } catch (_) {
          if (mounted) {
            setState(() {
              _fareEstimation = null;
              _totalFare = 0.0;
            });
          }
        } finally {
          if (mounted) {
            setState(() => _isEstimating = false);
          }
        }
      } else {
        setState(() {
          _fareEstimation = null;
          _totalFare = 0.0;
        });
      }
    });
  }

  void _goToStep(int targetStep) {
    setState(() {
      _step = targetStep;
      _isCourierDropdownOpen = false;
      _isCityDropdownOpen = false;
      if (targetStep > _furthestStep) _furthestStep = targetStep;
    });
    _calculateFare();
  }

  void _handleContinue() {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isCourierDropdownOpen = false;
      _isCityDropdownOpen = false;
    });

    if (_step == 0) {
      final nameErr = _validateSenderName(_senderNameCtrl.text);
      final phoneErr = _validateSenderPhone(_senderPhoneCtrl.text);
      final addrErr = _validatePickupAddress(_pickupAddressCtrl.text);
      final landmarkErr = _validateLandmark(_pickupLandmarkCtrl.text);
      final cityErr = _validateCity(_pickupCityCtrl.text);
      final stateErr = _validateState(_pickupStateCtrl.text);
      final pinErr = _validatePincode(_pickupPincodeCtrl.text);

      setState(() {
        _fieldErrors['senderName'] = nameErr;
        _fieldErrors['senderPhone'] = phoneErr;
        _fieldErrors['pickupAddress'] = addrErr;
        _fieldErrors['pickupLandmark'] = landmarkErr;
        _fieldErrors['pickupCity'] = cityErr;
        _fieldErrors['pickupState'] = stateErr;
        _fieldErrors['pickupPincode'] = pinErr;
      });

      final firstError = nameErr ?? phoneErr ?? addrErr ?? landmarkErr ?? cityErr ?? stateErr ?? pinErr;
      if (firstError != null) {
        AppSnackBar.showError(context, firstError);
        return;
      }
      if (_pickupLat == null || _pickupLng == null) {
        AppSnackBar.showError(context, l10n.pickupLocation);
        return;
      }
      _goToStep(1);
    } else if (_step == 1) {
      if (_selectedCourierId.isEmpty) {
        AppSnackBar.showError(context, l10n.courierPartnerLabel);
        return;
      }
      if (_isOtherCourier) {
        final courierErr = _validateCustomCourier(_customCourierCtrl.text);
        setState(() => _fieldErrors['customCourier'] = courierErr);
        if (courierErr != null) {
          AppSnackBar.showError(context, courierErr);
          return;
        }
      }
      if (_destinationCity.isEmpty) {
        AppSnackBar.showError(context, l10n.destinationCityLabel);
        return;
      }
      if (_bookingDurationMode == 'custom_days') {
        final daysErr = _validateCustomDays(_customDaysCtrl.text);
        setState(() => _fieldErrors['customDays'] = daysErr);
        if (daysErr != null) {
          AppSnackBar.showError(context, daysErr);
          return;
        }
      }
      _goToStep(2);
    } else if (_step == 2) {
      final weightErr = _validateWeight(_weightCtrl.text);
      final descErr = _validateDescription(_descriptionCtrl.text);
      setState(() {
        _fieldErrors['weight'] = weightErr;
        _fieldErrors['description'] = descErr;
      });
      final firstErr = weightErr ?? descErr;
      if (firstErr != null) {
        AppSnackBar.showError(context, firstErr);
        return;
      }
      _goToStep(3);
    } else if (_step == 3) {
      _submitBooking();
    }
  }

  void _openMapPickerDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => OutstationMapPickerDialog(
        initialLat: _pickupLat ?? 22.7560,
        initialLng: _pickupLng ?? 75.8657,
        onLocationConfirmed: (lat, lng, address, details) {
          setState(() {
            _pickupLat = lat;
            _pickupLng = lng;
            if (details != null) {
              _pickupAddressCtrl.text = details.street ?? details.area ?? '';
              _pickupLandmarkCtrl.text = details.area ?? '';
              _pickupCityCtrl.text = details.city ?? '';
              _pickupStateCtrl.text = details.state ?? '';
              _pickupPincodeCtrl.text = details.pincode ?? '';
            } else if (_pickupLandmarkCtrl.text.trim().isEmpty &&
                address.isNotEmpty) {
              _pickupLandmarkCtrl.text = address;
            }
          });
          _fetchNearestWarehouse(lat, lng);
          _calculateFare();
          final l10n = AppLocalizations.of(context)!;
          AppSnackBar.showSuccess(
            context,
            '${l10n.pickupLocation}: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
          );
        },
      ),
    );
  }

  void _showCategoryPicker() {
    final categories = _packageSegment == 'personal'
        ? _personalCategories
        : _businessCategories;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.selectPackageCategoryTitle,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 20.0,
                        color: Color(0xFF64748B),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (ctx, index) {
                    final cat = categories[index];
                    final isSelected = _packageCategory == cat;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 2.0,
                      ),
                      title: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF334155),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Color(0xFF0F172A),
                              size: 18.0,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _packageCategory = cat;
                          // keep value in sync for pro payload
                          final obj = _apiPackageCategories.firstWhere(
                            (e) => e['label'] == cat,
                            orElse: () => <String, dynamic>{'value': cat},
                          );
                          _selectedPackageCategoryValue = obj['value']?.toString() ?? cat;
                          // derive packageType from API if available (first active type)
                          if (_apiPackageTypes.isNotEmpty) {
                            _selectedPackageTypeValue = (_apiPackageTypes.firstWhere(
                              (e) => e['isActive'] == true,
                              orElse: () => _apiPackageTypes.first,
                            )['value'] as String);
                          }
                        });
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitBooking() async {
    setState(() => _isSubmitting = true);
    try {
      final client = ApiClient.createDefault();
      final composedPickup = [
        _pickupAddressCtrl.text.trim(),
        _pickupLandmarkCtrl.text.trim().isNotEmpty
            ? 'Near ${_pickupLandmarkCtrl.text.trim()}'
            : '',
        _pickupCityCtrl.text.trim(),
        _pickupStateCtrl.text.trim(),
        _pickupPincodeCtrl.text.trim(),
      ].where((s) => s.isNotEmpty).join(', ');

      final courierName = _isOtherCourier
          ? (_customCourierCtrl.text.trim().isNotEmpty
                ? _customCourierCtrl.text.trim()
                : 'Custom Courier')
          : (_selectedCourier?['name'] ?? 'Courier');

      final destinationCityObj = _destinationCities.firstWhere(
        (c) => c['name'] == _destinationCity,
        orElse: () => _destinationCities.first,
      );

      final duration = _resolveBookingDurationParams();

      final courierId = _selectedCourier?['id'];
      final warehouseId =
          _nearestWarehouse?['id']?.toString() ??
          _nearestWarehouse?['_id']?.toString();

      // Ensure category value is synced before payload
      if (_apiPackageCategories.isNotEmpty) {
        final catObj = _apiPackageCategories.firstWhere(
          (e) => e['label'] == _packageCategory,
          orElse: () => <String, dynamic>{'value': _packageCategory},
        );
        _selectedPackageCategoryValue = catObj['value']?.toString() ?? _packageCategory;
      }
      final safePickupName = _sanitizePersonName(_senderNameCtrl.text.trim());
      final digitsOnly = _senderPhoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
      final rawPhone = digitsOnly.isNotEmpty ? '+91$digitsOnly' : '';
      final payload = {
        'pickupAddress': {
          'name': safePickupName,
          'phone': rawPhone,
          'fullAddress': composedPickup,
          'street': _pickupAddressCtrl.text.trim(),
          'landmark': _pickupLandmarkCtrl.text.trim(),
          'city': _pickupCityCtrl.text.trim(),
          'state': _pickupStateCtrl.text.trim(),
          'pincode': _pickupPincodeCtrl.text.trim(),
          'lat': _pickupLat,
          'lng': _pickupLng,
        },
        'dropAddress': {
          'name': courierName,
          'phone': rawPhone,
          'fullAddress': '$courierName drop point, $_destinationCity',
          'lat': destinationCityObj['lat'],
          'lng': destinationCityObj['lng'],
        },
        'packageDetails': {
          'packageType': _selectedPackageTypeValue.isNotEmpty ? _selectedPackageTypeValue : 'other',
          'packageSegment': _packageSegment,
          'packageCategory': _selectedPackageCategoryValue.isNotEmpty ? _selectedPackageCategoryValue : _packageCategory,
          'weight': _effectiveWeightKg,
          'description': _descriptionCtrl.text.trim(),
        },
        'courierCompany': courierName,
        if (courierId != null && courierId.toString().isNotEmpty) 'courierCompanyId': courierId,
        if (_isOtherCourier && _customCourierCtrl.text.trim().isNotEmpty) 'customCourierName': _customCourierCtrl.text.trim(),
        'destinationCity': _destinationCity,
        if (warehouseId != null && warehouseId.toString().isNotEmpty) 'warehouseId': warehouseId,
        'parcelType': 'outstation',
        'pickupWindow': duration['pickupWindow'],
        'pickupWindowDays': duration['pickupWindowDays'],
        'preferredPickupDate': duration['preferredPickupDate'],
        'deliverySpeed': _deliverySpeed,
        'paymentMethod': _paymentMethod,
        if (_appliedCoupon != null) 'couponCode': _appliedCoupon!.code,
      };
      final res = await client.post(ApiEndpoints.outstationParcelCreate, data: payload);

      final creation = BookingCreationResult.fromJson(res);

      if (creation.parcelId.isEmpty) {
        // Never fabricate an id. The previous fallback navigated to
        // /parcel/outstation/track/out_<timestamp>, showing a success screen
        // for a parcel that does not exist.
        if (mounted) {
          AppSnackBar.showError(
            context,
            'The booking did not go through. Please try again.',
          );
        }
        return;
      }

      if (creation.isBrokenPaymentSetup) {
        if (mounted) {
          AppSnackBar.showError(
            context,
            'Online payment is unavailable right now. Choose cash on pickup.',
          );
        }
        return;
      }

      if (creation.isPayable) {
        // The backend holds the parcel at REQUESTED and dispatches no rider
        // until a verified Razorpay signature comes back.
        await _runCheckout(creation);
        return;
      }

      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          AppLocalizations.of(context)!.bookingCreatedNotifying,
        );
        _handleSuccess(creation.parcelId);
      }
    } catch (e) {
      if (mounted) {
        final msg = (e is ApiException && e.message.isNotEmpty)
            ? e.message
            : AppLocalizations.of(context)!.error;
        AppSnackBar.showError(context, msg);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Opens Razorpay for an outstation booking and confirms it with the server.
  Future<void> _runCheckout(BookingCreationResult creation) async {
    final order = creation.razorpayOrder!;
    final user = context.read<AuthBloc>().state.user;

    final result = await _checkout.open(
      order: order,
      description: 'SunGguard outstation parcel',
      contact: user?.phone ?? _senderPhoneCtrl.text,
      email: user?.email ?? '',
    );

    if (!mounted) return;

    if (!result.success || result.paymentId == null || result.signature == null) {
      AppSnackBar.showError(
        context,
        result.cancelled
            ? 'Payment cancelled. Your booking is saved — pay to confirm it.'
            : (result.message ?? 'Payment failed'),
      );
      return;
    }

    try {
      final client = ApiClient.createDefault();
      await client.post(
        ApiEndpoints.outstationParcelVerifyPayment,
        data: {
          // This endpoint takes the parcel id in the body, unlike the city
          // one which takes it in the path.
          'parcelId': creation.parcelId,
          'razorpay_order_id': result.orderId ?? order.orderId,
          'razorpay_payment_id': result.paymentId,
          'razorpay_signature': result.signature,
        },
      );
      if (!mounted) return;
      AppSnackBar.showSuccess(
        context,
        AppLocalizations.of(context)!.bookingCreatedNotifying,
      );
      _handleSuccess(creation.parcelId);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        (e is ApiException && e.message.isNotEmpty)
            ? e.message
            : "We couldn't confirm the payment. If you were charged, it will "
                'be applied shortly.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18.0,
            color: Color(0xFF0F172A),
          ),
          onPressed: () {
            if (_step > 0) {
              _goToStep(_step - 1);
            } else {
              _handleBack();
            }
          },
        ),
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.outstationBookingTitle,
          style: AppTypography.headingLarge.copyWith(
            fontSize: 18.0,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Masthead ──────────────────────────────────────────────────
            _buildMasthead(),

            const SizedBox(height: 16.0),

            // ── Waybill Stub Card (Route Rail + Barcode + Live Total) ──────
            _buildWaybillStub(),

            const SizedBox(height: 20.0),

            // ── Step Heading ──────────────────────────────────────────────
            _buildStepHeading(),

            const SizedBox(height: 12.0),

            // ── Step Content ──────────────────────────────────────────────
            _buildCurrentStepContent(),

            const SizedBox(height: 24.0),

            // ── In-flow Action Buttons (Back + Continue / Confirm) ────────
            _buildInFlowActionButtons(),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // MASTHEAD
  // =========================================================================
  Widget _buildMasthead() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COURIER DROP-OFF · UP TO ${_maxWeightKg.toInt()} KG',
          style: AppTypography.monoLabel.copyWith(
            fontSize: 10.0,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF64748B),
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 6.0),
        const Text(
          'Skip the courier\ncounter queue.',
          style: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            height: 1.08,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8.0),
        const Text(
          'A rider collects your parcel from your door and hands it to the courier company you choose. You fill this waybill once.',
          style: TextStyle(
            fontSize: 13.5,
            color: Color(0xFF64748B),
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // WAYBILL STUB CARD (Route Rail + Barcode + Estimate)
  // =========================================================================
  Widget _buildWaybillStub() {
    final l10n = AppLocalizations.of(context)!;
    final steps = [
      {'label': l10n.stepFrom},
      {'label': l10n.stepTo},
      {'label': l10n.stepWhat},
      {'label': l10n.stepPay},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 18.0,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Route Rail
          Padding(
            padding: const EdgeInsets.fromLTRB(18.0, 18.0, 18.0, 14.0),
            child: Row(
              children: List.generate(steps.length, (index) {
                final isDone = index < _step;
                final isCurrent = index == _step;
                final isReachable = index <= _furthestStep;

                return Expanded(
                  child: GestureDetector(
                    onTap: isReachable ? () => _goToStep(index) : null,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            if (index > 0)
                              Expanded(
                                child: Container(
                                  height: 2.0,
                                  color: index <= _step
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                            Container(
                              width: 32.0,
                              height: 32.0,
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? Colors.white
                                    : (isDone
                                          ? const Color(0xFF0F172A)
                                          : Colors.white),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isCurrent
                                      ? const Color(0xFF0F172A)
                                      : (isDone
                                            ? const Color(0xFF0F172A)
                                            : const Color(0xFFCBD5E1)),
                                  width: 2.0,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: isDone
                                  ? const Icon(
                                      Icons.check,
                                      size: 16.0,
                                      color: Colors.white,
                                    )
                                  : (isCurrent
                                        ? (index == 3
                                              ? Container(
                                                  width: 10.0,
                                                  height: 10.0,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Color(
                                                          0xFF0F172A,
                                                        ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                )
                                              : Container(
                                                  width: 14.0,
                                                  height: 14.0,
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF0F172A,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4.0,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.inventory_2_outlined,
                                                    size: 10.0,
                                                    color: Colors.white,
                                                  ),
                                                ))
                                        : null),
                            ),
                            if (index < steps.length - 1)
                              Expanded(
                                child: Container(
                                  height: 2.0,
                                  color: index < _step
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          steps[index]['label']!,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isCurrent
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isCurrent
                                ? const Color(0xFF0F172A)
                                : const Color(0xFF64748B),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          const PerforationLine(color: Color(0xFFF1F5F9)),

          // Barcode & Estimate
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 14.0,
            ),
            child: Row(
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
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    InkBarcode(
                      seed: 'SUNGGUARD-PARCEL',
                      ratio: _formCompletionRatio,
                      height: 24.0,
                    ),
                  ],
                ),
                AnimatedOpacity(
                  opacity: _isEstimating ? 0.4 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _isEstimating ? l10n.pricing : l10n.estimate,
                        style: AppTypography.monoLabel.copyWith(
                          fontSize: 9.0,
                          color: const Color(0xFF64748B),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      AnimatedMoneyText(
                        value: _payableFare,
                        style: AppTypography.monoData.copyWith(
                          fontSize: 22.0,
                          fontWeight: FontWeight.w900,
                          color: (_totalFare > 0 && _fareEstimation != null)
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeading() {
    final l10n = AppLocalizations.of(context)!;
    String heading;
    switch (_step) {
      case 0:
        heading = l10n.stepQuestionCollect;
        break;
      case 1:
        heading = l10n.outstationStep1Title;
        break;
      case 2:
        heading = l10n.stepQuestionCarrying;
        break;
      case 3:
      default:
        heading = l10n.outstationStep3Title;
        break;
    }

    return Text(
      heading,
      style: const TextStyle(
        fontSize: 19.0,
        fontWeight: FontWeight.w900,
        color: Color(0xFF0F172A),
        letterSpacing: -0.4,
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_step) {
      case 0:
        return _buildStep0From();
      case 1:
        return _buildStep1To();
      case 2:
        return _buildStep2What();
      case 3:
      default:
        return _buildStep3Pay();
    }
  }

  // =========================================================================
  // STEP 0: FROM (Collection Point)
  // =========================================================================
  Widget _buildStep0From() {
    return Column(
      children: [
        // 1. Sender Details Sheet Card
        _buildSheetCard([
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldCaption(
                      'SENDER',
                      _senderNameCtrl.text.trim().isNotEmpty,
                    ),
                    const SizedBox(height: 6.0),
                    _buildInputField(
                      _senderNameCtrl,
                      'Full name',
                      icon: Icons.person_outline_rounded,
                      errorText: _fieldErrors['senderName'],
                      onChanged: (val) {
                        if (_fieldErrors['senderName'] != null) {
                          setState(() => _fieldErrors['senderName'] = _validateSenderName(val));
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldCaption(
                      'PHONE',
                      _senderPhoneCtrl.text.trim().isNotEmpty,
                    ),
                    const SizedBox(height: 6.0),
                    _buildInputField(
                      _senderPhoneCtrl,
                      '10-digit',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      errorText: _fieldErrors['senderPhone'],
                      onChanged: (val) {
                        if (_fieldErrors['senderPhone'] != null) {
                          setState(() => _fieldErrors['senderPhone'] = _validateSenderPhone(val));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ]),

        const SizedBox(height: 12.0),

        // 2. Pickup Address Details Sheet Card
        _buildSheetCard([
          _buildFieldCaption(
            'HOUSE / FLAT / STREET',
            _pickupAddressCtrl.text.trim().isNotEmpty,
          ),
          const SizedBox(height: 6.0),
          _buildInputField(
            _pickupAddressCtrl,
            'Flat no, building, street or area',
            minLines: 2,
            maxLines: 3,
            errorText: _fieldErrors['pickupAddress'],
            onChanged: (val) {
              if (_fieldErrors['pickupAddress'] != null) {
                setState(() => _fieldErrors['pickupAddress'] = _validatePickupAddress(val));
              }
            },
          ),
          const SizedBox(height: 14.0),
          _buildFieldCaption(
            'LANDMARK',
            _pickupLandmarkCtrl.text.trim().isNotEmpty,
            hint: 'Optional, but riders find you faster with one.',
          ),
          const SizedBox(height: 6.0),
          _buildInputField(
            _pickupLandmarkCtrl,
            'Near City Mall',
            errorText: _fieldErrors['pickupLandmark'],
            onChanged: (val) {
              if (_fieldErrors['pickupLandmark'] != null) {
                setState(() => _fieldErrors['pickupLandmark'] = _validateLandmark(val));
              }
            },
          ),
          const SizedBox(height: 14.0),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldCaption(
                      'CITY',
                      _pickupCityCtrl.text.trim().isNotEmpty,
                    ),
                    const SizedBox(height: 6.0),
                    _buildInputField(
                      _pickupCityCtrl,
                      'City',
                      errorText: _fieldErrors['pickupCity'],
                      onChanged: (val) {
                        if (_fieldErrors['pickupCity'] != null) {
                          setState(() => _fieldErrors['pickupCity'] = _validateCity(val));
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldCaption(
                      'STATE',
                      _pickupStateCtrl.text.trim().isNotEmpty,
                    ),
                    const SizedBox(height: 6.0),
                    _buildInputField(
                      _pickupStateCtrl,
                      'State',
                      errorText: _fieldErrors['pickupState'],
                      onChanged: (val) {
                        if (_fieldErrors['pickupState'] != null) {
                          setState(() => _fieldErrors['pickupState'] = _validateState(val));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          _buildFieldCaption(
            'PINCODE',
            _pickupPincodeCtrl.text.trim().isNotEmpty,
          ),
          const SizedBox(height: 6.0),
          _buildInputField(
            _pickupPincodeCtrl,
            '110075',
            keyboardType: TextInputType.number,
            maxLength: 6,
            isMonospace: true,
            letterSpacing: 4.0,
            errorText: _fieldErrors['pickupPincode'],
            onChanged: (val) {
              final cleaned = val.replaceAll(RegExp(r'\D'), '');
              if (cleaned.length <= 6 && cleaned != val) {
                _pickupPincodeCtrl.text = cleaned;
              }
              if (_fieldErrors['pickupPincode'] != null) {
                setState(() => _fieldErrors['pickupPincode'] = _validatePincode(val));
              }
            },
          ),
        ]),

        const SizedBox(height: 12.0),

        // 3. Map Pin (Dashed Border Card)
        GestureDetector(
          onTap: _openMapPickerDialog,
          child: CustomPaint(
            painter: DashedBorderPainter(
              color: _pickupLat != null
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : const Color(0xFFCBD5E1),
              strokeWidth: 1.5,
              radius: 26.0,
              dashLength: 6.0,
              dashGap: 4.5,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: _pickupLat != null
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(26.0),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: _pickupLat != null
                          ? AppColors.primary
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: _pickupLat != null
                          ? Colors.white
                          : const Color(0xFF64748B),
                      size: 20.0,
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _pickupLat != null
                              ? 'Pickup point set'
                              : 'Drop a pin on the map',
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          _pickupLat != null
                              ? '${_pickupLat!.toStringAsFixed(4)}, ${_pickupLng!.toStringAsFixed(4)}'
                              : 'The fare needs an exact location',
                          style: const TextStyle(
                            fontSize: 11.0,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_pickupLat != null)
                    Icon(Icons.check, color: AppColors.primary, size: 20.0),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12.0),

        // 4. Ratings & reviews Section
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26.0),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 10.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () =>
                    setState(() => _reviewsExpanded = !_reviewsExpanded),
                borderRadius: BorderRadius.circular(26.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18.0,
                    vertical: 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 20.0,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8.0),
                                const Text(
                                  'Ratings & reviews',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4.0),
                            const Text(
                              'What other users say about our parcel service',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFFFBBF24),
                                size: 18.0,
                              ),
                              const SizedBox(width: 3.0),
                              Text(
                                _avgRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 17.0,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 3.0),
                              Icon(
                                _reviewsExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: const Color(0xFF64748B),
                                size: 18.0,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            '$_reviewCount REVIEW${_reviewCount == 1 ? '' : 'S'}',
                            style: AppTypography.monoLabel.copyWith(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_reviewsExpanded) ...[
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (_reviewItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            'No reviews yet. Be the first to review!',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ..._reviewItems
                          .take(3)
                          .map(
                            (review) => Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: _buildReviewTile(
                                review['customerName']?.toString() ??
                                    'Customer',
                                review['comment']?.toString() ??
                                    'Rated the parcel service.',
                                (review['rating'] as num?)?.toString() ?? '5',
                                review['createdAt'] != null
                                    ? DateFormat('d MMM').format(
                                        DateTime.tryParse(
                                              review['createdAt'].toString(),
                                            ) ??
                                            DateTime.now(),
                                      )
                                    : '',
                              ),
                            ),
                          ),
                      if (_reviewItems.length > 3 || _reviewCount > 3)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                            ),
                            onPressed: _openAllReviewsModal,
                            child: const Text(
                              'See all reviews',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _openAllReviewsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.0)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'All reviews',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        '${_avgRating.toStringAsFixed(1)} avg · $_reviewCount review${_reviewCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 20.0,
                      color: Color(0xFF64748B),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24.0, color: Color(0xFFF1F5F9)),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: _reviewItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10.0),
                  itemBuilder: (context, index) {
                    final item = _reviewItems[index];
                    return _buildReviewTile(
                      item['customerName']?.toString() ?? 'Customer',
                      item['comment']?.toString() ??
                          'Rated the parcel service.',
                      (item['rating'] as num?)?.toString() ?? '5',
                      item['createdAt'] != null
                          ? DateFormat('d MMM').format(
                              DateTime.tryParse(item['createdAt'].toString()) ??
                                  DateTime.now(),
                            )
                          : '',
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewTile(
    String name,
    String comment,
    String ratingStr,
    String date,
  ) {
    final rating = int.tryParse(ratingStr) ?? 5;
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (n) => Icon(
                Icons.star_rounded,
                size: 16.0,
                color: (n + 1) <= rating
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFFCBD5E1),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            comment.isNotEmpty ? '“$comment”' : '“Rated the parcel service.”',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (date.isNotEmpty)
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 1: TO (Destination, Handoff Diagram & Courier Partner)
  // =========================================================================
  Widget _buildStep1To() {
    final selectedCourierName = _selectedCourier?['name'];
    final hasSelectedCourier = _selectedCourierId.isNotEmpty;

    return Column(
      children: [
        // ── Card 1: Handoff Visual Diagram & Drop Point Warehouse ──────
        _buildSheetCard([
          _buildHandoffDiagram(),
          if (_nearestWarehouse != null) ...[
            const SizedBox(height: 16.0),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 14.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Icon(
                    Icons.store_mall_directory_outlined,
                    color: Color(0xFFEA580C),
                    size: 20.0,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DROP POINT: NEAREST WAREHOUSE',
                        style: AppTypography.monoLabel.copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFEA580C),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 3.0),
                      Text(
                        _nearestWarehouse?['name']?.toString() ??
                            'Nearest Warehouse',
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (_nearestWarehouse?['address'] != null ||
                          _nearestWarehouse?['fullAddress'] != null ||
                          _nearestWarehouse?['city'] != null) ...[
                        const SizedBox(height: 2.0),
                        Text(
                          [
                            _nearestWarehouse?['address']?.toString() ??
                                _nearestWarehouse?['fullAddress']?.toString(),
                            _nearestWarehouse?['city']?.toString(),
                          ].where((s) => s != null && s.isNotEmpty).join(', '),
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4.0),
                      const Text(
                        'Rider will pick up from you and deliver here for onward dispatch.',
                        style: TextStyle(
                          fontSize: 11.0,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ]),

        const SizedBox(height: 12.0),

        // ── Card 2: Courier Company & Destination City ─────────────────
        _buildSheetCard([
          _buildFieldCaption('COURIER COMPANY', hasSelectedCourier),
          const SizedBox(height: 6.0),
          GestureDetector(
            onTap: () {
              setState(() {
                _isCourierDropdownOpen = !_isCourierDropdownOpen;
                _isCityDropdownOpen = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 13.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(
                  color: _isCourierDropdownOpen
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFE2E8F0),
                  width: _isCourierDropdownOpen ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hasSelectedCourier && selectedCourierName != null
                        ? selectedCourierName
                        : 'Select a courier company',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: hasSelectedCourier
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  Icon(
                    _isCourierDropdownOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20.0,
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),

          // ── Inline Floating Popup for Courier Company ────────────────
          if (_isCourierDropdownOpen) ...[
            const SizedBox(height: 6.0),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x140F172A),
                    blurRadius: 16.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 6.0),
                    child: Text(
                      'Pick a courier company',
                      style: TextStyle(
                        fontSize: 13.0,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ..._courierCompanies.map((c) {
                    final isSelected = _selectedCourierId == c['id'];
                    final isOther = c['isOther'] == true;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCourierId = c['id'];
                          _isCourierDropdownOpen = false;
                        });
                        _calculateFare();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        color: isSelected
                            ? const Color(0xFFF8FAFC)
                            : Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isOther ? 'Another company' : c['name'],
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            if (!isOther)
                              Text(
                                '₹${(c['platformCharge'] as num).toDouble().toStringAsFixed(2)}',
                                style: AppTypography.monoLabel.copyWith(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          const SizedBox(height: 4.0),
          Text(
            hasSelectedCourier
                ? 'Their platform charge is already in the fare.'
                : 'Whoever you normally post with.',
            style: const TextStyle(
              fontSize: 11.0,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),

          if (_isOtherCourier) ...[
            const SizedBox(height: 10.0),
            _buildFieldCaption('COMPANY NAME', _customCourierSaved),
            const SizedBox(height: 6.0),
            _buildInputField(
              _customCourierCtrl,
              'Courier company name',
              icon: Icons.business_outlined,
              errorText: _fieldErrors['customCourier'],
              onChanged: (val) {
                setState(() => _customCourierSaved = val.trim().isNotEmpty);
                if (_fieldErrors['customCourier'] != null) {
                  setState(() => _fieldErrors['customCourier'] = _validateCustomCourier(val));
                }
                _calculateFare();
              },
            ),
          ],

          const SizedBox(height: 14.0),

          _buildFieldCaption('DESTINATION CITY', _destinationCity.isNotEmpty),
          const SizedBox(height: 6.0),
          GestureDetector(
            onTap: () {
              setState(() {
                _isCityDropdownOpen = !_isCityDropdownOpen;
                _isCourierDropdownOpen = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 13.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(
                  color: _isCityDropdownOpen
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFE2E8F0),
                  width: _isCityDropdownOpen ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _destinationCity.isNotEmpty
                        ? _destinationCity
                        : 'Pick a destination city',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: _destinationCity.isNotEmpty
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  Icon(
                    _isCityDropdownOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20.0,
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),

          // ── Inline Floating Popup for Destination City ───────────────
          if (_isCityDropdownOpen) ...[
            const SizedBox(height: 6.0),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x140F172A),
                    blurRadius: 16.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 6.0),
                      child: Text(
                        'Pick a destination city',
                        style: TextStyle(
                          fontSize: 13.0,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ..._destinationCities.map((city) {
                      final name = city['name'] as String;
                      final isSelected = _destinationCity == name;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _destinationCity = name;
                            _isCityDropdownOpen = false;
                          });
                          _calculateFare();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          color: isSelected
                              ? const Color(0xFFF8FAFC)
                              : Colors.transparent,
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 4.0),
          const Text(
            'Where the parcel finally lands.',
            style: TextStyle(
              fontSize: 11.0,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ]),

        const SizedBox(height: 12.0),

        // ── Card 3: Booking Duration Modes ─────────────────────────────
        _buildSheetCard([
          _buildFieldCaption('BOOK PICKUP FOR', true),
          const SizedBox(height: 8.0),
          Row(
            children: [
              _buildDurationPill('one_day', 'One day', 'Today only'),
              const SizedBox(width: 8.0),
              _buildDurationPill('custom_days', 'Custom days', 'Set a count'),
              const SizedBox(width: 8.0),
              _buildDurationPill('by_date', 'Until a date', 'Pick an end'),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            _bookingDurationMode == 'one_day'
                ? 'Today only.'
                : (_bookingDurationMode == 'custom_days'
                      ? 'Set a count.'
                      : 'Pick an end.'),
            style: const TextStyle(
              fontSize: 11.0,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),

          if (_bookingDurationMode == 'custom_days') ...[
            const SizedBox(height: 14.0),
            _buildFieldCaption('NUMBER OF DAYS', true),
            const SizedBox(height: 6.0),
            _buildInputField(
              _customDaysCtrl,
              '7',
              icon: Icons.timer_outlined,
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculateFare(),
            ),
            const SizedBox(height: 4.0),
            const Text(
              'A rider is available each day, up to 30.',
              style: TextStyle(
                fontSize: 11.0,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          if (_bookingDurationMode == 'by_date') ...[
            const SizedBox(height: 14.0),
            _buildFieldCaption('BOOK UNTIL', true),
            const SizedBox(height: 6.0),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _preferredPickupDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: Color(0xFF60A5FA),
                          onPrimary: Colors.white,
                          surface: Color(0xFF1E293B),
                          onSurface: Colors.white,
                        ),
                        dialogTheme: const DialogThemeData(
                          backgroundColor: Color(0xFF0F172A),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _preferredPickupDate = picked);
                  _calculateFare();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16.0,
                          color: Color(0xFF0F172A),
                        ),
                        const SizedBox(width: 10.0),
                        Text(
                          DateFormat('dd MMM yyyy')
                              .format(_preferredPickupDate),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4.0),
            const Text(
              'The last date you want daily pickup.',
              style: TextStyle(
                fontSize: 11.0,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 12.0),

          // Clock Helper Container
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 16.0,
                  color: Color(0xFF0F172A),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: Color(0xFF475569),
                        fontFamily: 'Outfit',
                      ),
                      children: _bookingDurationMode == 'one_day'
                          ? [
                              const TextSpan(text: 'Pickup is available '),
                              const TextSpan(
                                text: 'today only.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ]
                          : (_bookingDurationMode == 'custom_days'
                                ? [
                                    const TextSpan(text: 'Daily pickup for '),
                                    TextSpan(
                                      text:
                                          '${_customDaysCtrl.text.trim().isNotEmpty ? _customDaysCtrl.text.trim() : '7'} days, ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const TextSpan(text: 'through '),
                                    TextSpan(
                                      text: DateFormat('d MMM yyyy').format(
                                        DateTime.now().add(
                                          Duration(
                                            days:
                                                int.tryParse(
                                                  _customDaysCtrl.text.trim(),
                                                ) ??
                                                7,
                                          ),
                                        ),
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const TextSpan(text: '.'),
                                  ]
                                : [
                                    const TextSpan(
                                      text: 'Daily pickup through ',
                                    ),
                                    TextSpan(
                                      text: DateFormat('d MMM yyyy')
                                          .format(_preferredPickupDate),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const TextSpan(text: '.'),
                                  ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildHandoffDiagram() {
    final courierName = _selectedCourier?['name'];
    final counterName = _isOtherCourier
        ? (_customCourierCtrl.text.trim().isNotEmpty
              ? _customCourierCtrl.text.trim()
              : 'COURIER COUNTER')
        : (courierName != null
              ? courierName.toString().toUpperCase()
              : 'COURIER COUNTER');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDiagramNode(
          'YOUR DOOR',
          Icons.location_on_outlined,
          isBrand: true,
        ),
        Expanded(
          child: Column(
            children: [
              Container(height: 2.0, color: const Color(0xFF0F172A)),
              const SizedBox(height: 4.0),
              Text(
                'OUR RIDER',
                style: AppTypography.monoLabel.copyWith(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
        _buildDiagramNode(
          counterName,
          Icons.storefront_outlined,
          isBrand: true,
        ),
        Expanded(
          child: Column(
            children: [
              Container(height: 2.0, color: const Color(0xFFCBD5E1)),
              const SizedBox(height: 4.0),
              Text(
                'THE COURIER',
                style: AppTypography.monoLabel.copyWith(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
        _buildDiagramNode(
          _destinationCity.toUpperCase(),
          Icons.navigation_outlined,
          isBrand: false,
        ),
      ],
    );
  }

  Widget _buildDiagramNode(
    String label,
    IconData icon, {
    required bool isBrand,
  }) {
    return Column(
      children: [
        Container(
          width: 36.0,
          height: 36.0,
          decoration: BoxDecoration(
            color: isBrand
                ? const Color(0xFF0F172A).withValues(alpha: 0.08)
                : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isBrand
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFCBD5E1),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            size: 17.0,
            color: isBrand ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6.0),
        SizedBox(
          width: 76.0,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.monoLabel.copyWith(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationPill(String key, String title, String sub) {
    final isSelected = _bookingDurationMode == key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _bookingDurationMode = key);
          _calculateFare();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11.0, horizontal: 6.0),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0F172A).withValues(alpha: 0.07)
                : Colors.white,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 9.5,
                  color: isSelected
                      ? const Color(0xFF0F172A).withValues(alpha: 0.8)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // STEP 2: WHAT (Weight, Speed, Segment & Description)
  // =========================================================================
  Widget _buildStep2What() {
    return Column(
      children: [
        // ── Card 1: Weight & Unit ──────────────────────────────────────
        _buildSheetCard([
          _buildFieldCaption(
            'WEIGHT · MAX ${_weightUnit == 'gm' ? '${(_maxWeightKg * 1000).toInt()} GM' : '${_maxWeightKg.toStringAsFixed(1)} KG'}',
            _effectiveWeightKg > 0 && _effectiveWeightKg <= _maxWeightKg,
          ),
          const SizedBox(height: 8.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _WeightBoxWidget(kg: _effectiveWeightKg, maxKg: _maxWeightKg),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: _effectiveWeightKg > 0
                                  ? AppColors.primary.withValues(alpha: 0.04)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14.0),
                              border: Border.all(
                                color: _effectiveWeightKg > _maxWeightKg
                                    ? const Color(0xFFDC2626)
                                    : (_effectiveWeightKg > 0
                                          ? AppColors.primary.withValues(
                                              alpha: 0.3,
                                            )
                                          : const Color(0xFFE2E8F0)),
                                width: _effectiveWeightKg > 0 ? 1.5 : 1.0,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                              vertical: 10.0,
                            ),
                            child: TextField(
                              controller: _weightCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.w800,
                                color: _effectiveWeightKg > _maxWeightKg
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF0F172A),
                                fontFamily: 'monospace',
                              ),
                              onChanged: (_) {
                                setState(() {});
                                _calculateFare();
                              },
                              decoration: InputDecoration(
                                hintText: _weightUnit == 'gm' ? '500' : '1',
                                hintStyle: const TextStyle(
                                  fontSize: 16.0,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14.0),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _weightUnit,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20.0,
                                color: Color(0xFF64748B),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'kg',
                                  child: Text(
                                    'KG',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.0,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'gm',
                                  child: Text(
                                    'GM',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.0,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null && val != _weightUnit) {
                                  final numVal = double.tryParse(
                                    _weightCtrl.text.trim(),
                                  );
                                  if (numVal != null && numVal > 0) {
                                    if (val == 'gm' && _weightUnit == 'kg') {
                                      _weightCtrl.text = (numVal * 1000)
                                          .toInt()
                                          .toString();
                                    } else if (val == 'kg' &&
                                        _weightUnit == 'gm') {
                                      final inKg = numVal / 1000.0;
                                      _weightCtrl.text = inKg.toString();
                                    }
                                  }
                                  setState(() => _weightUnit = val);
                                  _calculateFare();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      _effectiveWeightKg > _maxWeightKg
                          ? 'Over the ${_maxWeightKg.toStringAsFixed(1)} kg limit'
                          : (_weightUnit == 'gm' && _effectiveWeightKg > 0
                                ? '= ${_effectiveWeightKg.toStringAsFixed(3)} KG'
                                : 'Limit ${_maxWeightKg.toStringAsFixed(1)} KG'),
                      style: AppTypography.monoLabel.copyWith(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w600,
                        color: _effectiveWeightKg > _maxWeightKg
                            ? const Color(0xFFB45309)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ]),

        const SizedBox(height: 12.0),

        // ── Card 2: Delivery Speed Mode ────────────────────────────────
        _buildSheetCard([
          _buildFieldCaption('HOW SOON SHOULD A RIDER ARRIVE?', true),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Expanded(child: _buildSpeedPill('normal', 'Normal', '30 min')),
              const SizedBox(width: 10.0),
              Expanded(
                child: _buildSpeedPill(
                  'express',
                  'Express',
                  '10 min · +₹${_expressChargeConfig.toInt()}.00',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          const Text(
            "This is the pickup wait, not the courier's transit time.",
            style: TextStyle(
              fontSize: 11.0,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ]),

        const SizedBox(height: 12.0),

        // ── Card 3: Sending As, Category, Description ──────────────────
        _buildSheetCard([
          _buildFieldCaption('SENDING AS', true),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Expanded(child: _buildSegmentPill('personal', 'Personal')),
              const SizedBox(width: 10.0),
              Expanded(child: _buildSegmentPill('business', 'Business')),
            ],
          ),

          const SizedBox(height: 14.0),

          _buildFieldCaption('CATEGORY', _packageCategory.isNotEmpty),
          const SizedBox(height: 6.0),
          GestureDetector(
            onTap: _showCategoryPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 13.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _packageCategory,
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20.0,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14.0),

          _buildFieldCaption(
            "WHAT'S INSIDE",
            _descriptionCtrl.text.trim().isNotEmpty,
          ),
          const SizedBox(height: 6.0),
          _buildInputField(
            _descriptionCtrl,
            _packageDescriptionPlaceholder,
            icon: Icons.notes_outlined,
            minLines: 2,
            maxLines: 3,
            errorText: _fieldErrors['description'],
            onChanged: (val) {
              if (_fieldErrors['description'] != null) {
                setState(() => _fieldErrors['description'] = _validateDescription(val));
              }
            },
          ),
          const SizedBox(height: 6.0),
          const Text(
            'Helps the rider handle it correctly.',
            style: TextStyle(
              fontSize: 11.0,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildSpeedPill(String key, String title, String sub) {
    final isSelected = _deliverySpeed == key;
    return GestureDetector(
      onTap: () {
        if (_deliverySpeed == key) return;
        setState(() {
          _deliverySpeed = key;
          // Optimistic UI price jump while the backend API debounces
          if (_fareEstimation != null && _totalFare > 0) {
            final days =
                (_fareEstimation!['billableDays'] as num?)?.toInt() ?? 1;
            final prevExpress =
                (_fareEstimation!['expressCharge'] as num?)?.toDouble() ?? 0.0;
            final nextExpress = (key == 'express') ? _expressChargeConfig : 0.0;
            final delta = (nextExpress - prevExpress) * days;
            _expressCharge = nextExpress;
            _totalFare = (_totalFare + delta).clamp(0.0, double.infinity);
          }
        });
        _calculateFare();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0F172A).withValues(alpha: 0.07)
              : Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F172A)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 3.0),
            Text(
              sub,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF0F172A).withValues(alpha: 0.8)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentPill(String key, String title) {
    final isSelected = _packageSegment == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _packageSegment = key;
          // API-driven default category for this segment
          if (_apiPackageCategories.isNotEmpty) {
            final segCats = _apiPackageCategories
                .where((e) => e['segment'] == key && e['isActive'] == true)
                .toList();
            if (segCats.isNotEmpty) {
              _packageCategory = segCats.first['label'] as String;
              _selectedPackageCategoryValue = segCats.first['value'] as String;
            } else {
              _packageCategory = key == 'personal' ? 'Gift' : 'Invoice / Bills';
            }
          } else {
            _packageCategory = key == 'personal' ? 'Gift' : 'Invoice / Bills';
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0F172A).withValues(alpha: 0.07)
              : Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F172A)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // STEP 3: PAY (Consignment Receipt & Payment)
  // =========================================================================
  Widget _buildStep3Pay() {
    final courierName = _selectedCourier?['name'];
    final counterName = _isOtherCourier
        ? (_customCourierCtrl.text.trim().isNotEmpty
              ? _customCourierCtrl.text.trim().toUpperCase()
              : 'COURIER COUNTER')
        : (courierName != null
              ? courierName.toString().toUpperCase()
              : 'COURIER COUNTER');

    return Column(
      children: [
        // ── Card 1: Payment Method ─────────────────────────────────────
        _buildSheetCard([
          _buildFieldCaption('HOW DO YOU WANT TO PAY?', true),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Expanded(child: _buildPaymentPill('COD', 'Cash', 'On pickup')),
              const SizedBox(width: 10.0),
              Expanded(child: _buildPaymentPill('UPI', 'UPI', 'Pay now')),
            ],
          ),
        ]),

        if (_fareEstimation != null && _totalFare > 0) ...[
          const SizedBox(height: 14.0),
          _buildCouponCard(),
        ],

        const SizedBox(height: 14.0),

        // ── Card 2: Dark Consignment Docket (#0B1220) ───────────────────
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0B1220),
            borderRadius: BorderRadius.circular(26.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x330B1220),
                blurRadius: 20.0,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Fare & Distance Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL TO PAY',
                        style: AppTypography.monoLabel.copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      AnimatedMoneyText(
                        value: _payableFare,
                        style: const TextStyle(
                          fontSize: 32.0,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                  if (_fareEstimation != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'DISTANCE',
                          style: AppTypography.monoLabel.copyWith(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '${_distanceKm.toStringAsFixed(2)} km',
                          style: AppTypography.monoData.copyWith(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              if (_fareEstimation != null) ...[
                const SizedBox(height: 14.0),
                _buildDottedLeaderLine(),
                const SizedBox(height: 14.0),

                // Fare Breakdown Dotted Leader Rows
                if (_baseFare > 0) ...[
                  _buildDottedLeaderRow(
                    'Base fare',
                    '₹${_baseFare.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8.0),
                ],
                if (_distanceFare > 0)
                  _buildDottedLeaderRow(
                    'Distance ${_distanceKm.toStringAsFixed(2)} km × ₹${_perKmCharge.toStringAsFixed(2)}',
                    '₹${_distanceFare.toStringAsFixed(2)}',
                  ),
                const SizedBox(height: 8.0),
                _buildDottedLeaderRow(
                  'Weight ${_effectiveWeightKg.toStringAsFixed(1)} kg',
                  '₹${_weightFare.toStringAsFixed(2)}',
                ),
                if (_platformCharge > 0) ...[
                  const SizedBox(height: 8.0),
                  _buildDottedLeaderRow(
                    'Platform charge',
                    '₹${_platformCharge.toStringAsFixed(2)}',
                  ),
                ],
                if (_deliverySpeed == 'express') ...[
                  const SizedBox(height: 8.0),
                  _buildDottedLeaderRow(
                    '⚡ Express surcharge',
                    '₹${_expressCharge.toStringAsFixed(2)}',
                  ),
                ],
                if (_appliedCoupon != null) ...[
                  const SizedBox(height: 8.0),
                  _buildDottedLeaderRow(
                    'Coupon (${_appliedCoupon!.code})',
                    '-₹${_appliedCoupon!.taxableDiscount.toStringAsFixed(2)}',
                  ),
                ],
                if ((_appliedCoupon?.taxAmount ?? _gstAmount) > 0) ...[
                  const SizedBox(height: 8.0),
                  _buildDottedLeaderRow(
                    'GST (${((_appliedCoupon?.taxPercent ?? 0) > 0 ? _appliedCoupon!.taxPercent : _gstPercent).toStringAsFixed(0)}%)',
                    '₹${(_appliedCoupon?.taxAmount ?? _gstAmount).toStringAsFixed(2)}',
                  ),
                ],

                const SizedBox(height: 14.0),
                _buildDottedLeaderLine(),
                const SizedBox(height: 14.0),
              ],

              // Bottom Route Trail & PRICED Stamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 13.0,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          'YOU  ·  ',
                          style: AppTypography.monoLabel.copyWith(
                            color: const Color(0xFF94A3B8),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Icon(
                          Icons.storefront_outlined,
                          size: 13.0,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4.0),
                        Flexible(
                          child: Text(
                            '$counterName  ·  ',
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.monoLabel.copyWith(
                              color: const Color(0xFF94A3B8),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.navigation_outlined,
                          size: 12.0,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          _destinationCity.toUpperCase(),
                          style: AppTypography.monoLabel.copyWith(
                            color: const Color(0xFF94A3B8),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_fareEstimation != null && !_isEstimating)
                    Transform.rotate(
                      angle: -0.08,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(
                            color: const Color(0xFF22C55E),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          'PRICED',
                          style: AppTypography.monoLabel.copyWith(
                            fontSize: 10.0,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF4ADE80),
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        if (_pickupLat == null || _fareEstimation == null) ...[
          const SizedBox(height: 14.0),
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFD97706),
                  size: 18.0,
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E),
                      ),
                      children: [
                        const TextSpan(
                          text: 'Set the pickup point on the map to see the distance and fare. ',
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: GestureDetector(
                            onTap: () => _goToStep(0),
                            child: const Text(
                              'Go back to From',
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF92400E),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCouponCard() {
    final applied = _appliedCoupon;
    return _buildSheetCard([
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildFieldCaption('COUPON', applied != null),
          if (applied != null)
            GestureDetector(
              onTap: () => setState(() {
                _appliedCoupon = null;
                _couponError = null;
                _couponCtrl.clear();
              }),
              child: Text(
                'REMOVE',
                style: AppTypography.monoLabel.copyWith(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFDC2626),
                  letterSpacing: 1.2,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8.0),
      if (applied != null)
        Text(
          '${applied.code} applied — you saved ₹${applied.discountAmount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 13.0,
            fontWeight: FontWeight.w700,
            color: Color(0xFF047857),
          ),
        )
      else ...[
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _couponCtrl,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [LengthLimitingTextInputFormatter(40)],
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter coupon code',
                    hintStyle: TextStyle(fontSize: 13.0, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 13.0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10.0),
            SizedBox(
              height: 46.0,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0F172A)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                ),
                onPressed: _couponCtrl.text.trim().isEmpty || _applyingCoupon
                    ? null
                    : () => _applyCoupon(_couponCtrl.text),
                child: _applyingCoupon
                    ? const SizedBox(
                        width: 16.0,
                        height: 16.0,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
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
        if (_couponError != null) ...[
          const SizedBox(height: 6.0),
          Text(
            _couponError!,
            style: const TextStyle(fontSize: 12.0, color: Color(0xFFDC2626)),
          ),
        ],
        if (_availableCoupons.isNotEmpty) ...[
          const SizedBox(height: 10.0),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _availableCoupons
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () => _applyCoupon(c.code),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 7.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(color: const Color(0xFF0F172A)),
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
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    ]);
  }

  Widget _buildPaymentPill(String key, String title, String sub) {
    final isSelected = _paymentMethod == key;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0F172A).withValues(alpha: 0.07)
              : Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F172A)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              sub,
              style: TextStyle(
                fontSize: 10.5,
                color: isSelected
                    ? const Color(0xFF0F172A).withValues(alpha: 0.8)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDottedLeaderRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final count = (constraints.maxWidth / 6.0).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  math.max(1, count),
                  (_) => Container(
                    width: 2.0,
                    height: 1.0,
                    color: const Color(0xFF334155),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8.0),
        Text(
          value,
          style: AppTypography.monoData.copyWith(
            color: const Color(0xFFF1F5F9),
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildDottedLeaderLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 6.0).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            math.max(1, count),
            (_) => Container(
              width: 3.0,
              height: 1.0,
              color: const Color(0xFF334155),
            ),
          ),
        );
      },
    );
  }

  // =========================================================================
  // IN-FLOW ACTION BUTTONS (Back + Continue / Confirm)
  // =========================================================================
  Widget _buildInFlowActionButtons() {
    return Row(
      children: [
        if (_step > 0) ...[
          GestureDetector(
            onTap: () => _goToStep(_step - 1),
            child: Container(
              width: 54.0,
              height: 54.0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18.0),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A0F172A),
                    blurRadius: 10.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFF0F172A),
                size: 20.0,
              ),
            ),
          ),
          const SizedBox(width: 10.0),
        ],
        Expanded(
          child: SizedBox(
            height: 54.0,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0),
                ),
              ),
              onPressed: _isSubmitting ? null : _handleContinue,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22.0,
                      height: 22.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _step == 3
                              ? (_paymentMethod == 'UPI'
                                    ? AppLocalizations.of(context)!
                                          .confirmAndPay(
                                            '₹${_payableFare.toStringAsFixed(2)}',
                                          )
                                    : AppLocalizations.of(context)!
                                          .payAndShipNow)
                              : AppLocalizations.of(context)!.continueText,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        const Icon(Icons.arrow_forward, size: 17.0),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // CARD & FIELD PRIMITIVES
  // =========================================================================
  Widget _buildSheetCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x050F172A),
            blurRadius: 12.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildFieldCaption(String label, bool filled, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.monoLabel.copyWith(
            fontSize: 10.0,
            fontWeight: FontWeight.w800,
            color: filled ? AppColors.primary : const Color(0xFF64748B),
            letterSpacing: 1.8,
          ),
        ),
        if (hint != null && hint.isNotEmpty) ...[
          const SizedBox(height: 2.0),
          Text(
            hint,
            style: const TextStyle(
              fontSize: 11.0,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String hint, {
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    int minLines = 1,
    int maxLines = 1,
    int? maxLength,
    bool isMonospace = false,
    double letterSpacing = 0.0,
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
    Function(String)? onChanged,
  }) {
    final filled = controller.text.trim().isNotEmpty;
    final hasError = errorText != null && errorText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: hasError
                ? const Color(0xFFFEF2F2)
                : (filled
                    ? AppColors.primary.withValues(alpha: 0.04)
                    : Colors.white),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: hasError
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFE2E8F0),
              width: hasError ? 1.5 : 1.0,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 14.0,
            vertical: minLines > 1 ? 12.0 : 4.0,
          ),
          child: Row(
            crossAxisAlignment: minLines > 1
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Padding(
                  padding: EdgeInsets.only(top: minLines > 1 ? 2.0 : 0.0),
                  child: Icon(
                    icon,
                    size: 16.0,
                    color: hasError
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 10.0),
              ],
              if (keyboardType == TextInputType.phone) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Text(
                    '+91',
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters ??
                      (keyboardType == TextInputType.phone
                          ? [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ]
                          : null),
                  minLines: minLines,
                  maxLines: maxLines,
                  maxLength: maxLength,
                  buildCounter: maxLength != null
                      ? (_, {currentLength = 0, isFocused = false, maxLength}) =>
                            null
                      : null,
                  onChanged: (val) {
                    setState(() {});
                    if (onChanged != null) onChanged(val);
                  },
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                    letterSpacing: letterSpacing,
                    fontFamily: isMonospace ? 'monospace' : null,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontSize: 14.0,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4.0),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              errorText,
              style: const TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// ANIMATED MONEY & WEIGHT BOX REUSABLE WIDGETS
// =============================================================================

class AnimatedMoneyText extends StatelessWidget {
  final double value;
  final TextStyle style;
  final String prefix;
  final int decimals;

  const AnimatedMoneyText({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '₹',
    this.decimals = 2,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text(
          '$prefix${animatedValue.toStringAsFixed(decimals)}',
          style: style,
        );
      },
    );
  }
}

class _WeightBoxWidget extends StatelessWidget {
  final double kg;
  final double maxKg;

  const _WeightBoxWidget({required this.kg, required this.maxKg});

  @override
  Widget build(BuildContext context) {
    final ratio = maxKg > 0 ? (kg / maxKg).clamp(0.0, 1.25) : 0.0;
    final isOver = kg > maxKg;
    final scale = 0.42 + (ratio.clamp(0.0, 1.0) * 0.58);
    final tone = isOver ? const Color(0xFFB45309) : AppColors.primary;

    return SizedBox(
      width: 92.0,
      height: 92.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: 76.0 * (0.5 + (ratio.clamp(0.0, 1.0) * 0.5)),
            height: 76.0 * (0.5 + (ratio.clamp(0.0, 1.0) * 0.5)),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tone.withValues(alpha: isOver ? 0.18 : 0.12),
            ),
          ),
          AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: CustomPaint(
              size: const Size(54.0, 54.0),
              painter: _IsometricCartonPainter(color: tone),
            ),
          ),
        ],
      ),
    );
  }
}

class _IsometricCartonPainter extends CustomPainter {
  final Color color;
  const _IsometricCartonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final outerPath = Path();
    outerPath.moveTo(w * (3.5 / 24.0), h * (7.6 / 24.0));
    outerPath.lineTo(w * (12.0 / 24.0), h * (3.0 / 24.0));
    outerPath.lineTo(w * (20.5 / 24.0), h * (7.6 / 24.0));
    outerPath.lineTo(w * (20.5 / 24.0), h * (16.4 / 24.0));
    outerPath.lineTo(w * (12.0 / 24.0), h * (21.0 / 24.0));
    outerPath.lineTo(w * (3.5 / 24.0), h * (16.4 / 24.0));
    outerPath.close();

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;
    canvas.drawPath(outerPath, fillPaint);

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(outerPath, strokePaint);

    final innerPath = Path();
    innerPath.moveTo(w * (3.7 / 24.0), h * (7.7 / 24.0));
    innerPath.lineTo(w * (12.0 / 24.0), h * (12.0 / 24.0));
    innerPath.lineTo(w * (20.3 / 24.0), h * (7.7 / 24.0));
    innerPath.moveTo(w * (12.0 / 24.0), h * (12.0 / 24.0));
    innerPath.lineTo(w * (12.0 / 24.0), h * (20.9 / 24.0));
    canvas.drawPath(innerPath, strokePaint);

    final creasePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final creasePath = Path();
    creasePath.moveTo(w * (7.7 / 24.0), h * (5.3 / 24.0));
    creasePath.lineTo(w * (16.3 / 24.0), h * (9.9 / 24.0));
    canvas.drawPath(creasePath, creasePaint);
  }

  @override
  bool shouldRepaint(covariant _IsometricCartonPainter oldDelegate) =>
      oldDelegate.color != color;
}
