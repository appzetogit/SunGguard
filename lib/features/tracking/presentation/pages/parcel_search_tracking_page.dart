import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../widgets/parcel_rating_sheet.dart';
import '../../../../l10n/app_localizations.dart';

class ParcelSearchTrackingPage extends StatefulWidget {
  final String parcelId;
  final VoidCallback? onBack;

  const ParcelSearchTrackingPage({
    super.key,
    required this.parcelId,
    this.onBack,
  });

  @override
  State<ParcelSearchTrackingPage> createState() =>
      _ParcelSearchTrackingPageState();
}

class _ParcelSearchTrackingPageState extends State<ParcelSearchTrackingPage>
    with TickerProviderStateMixin {
  final ApiClient _client = ApiClient.createDefault();
  SocketService? _socketService;

  Map<String, dynamic>? _parcel;
  bool _isLoading = true;
  bool _isCancelling = false;
  bool _isRequestingLateRefund = false;

  /// Whether this customer has already rated the parcel. Read from
  /// GET /parcel/review/:parcelId, which returns the review or null.
  bool _hasReviewed = false;
  bool _reviewChecked = false;
  int _existingRating = 0;

  int _sliderIndex = 0;
  Timer? _sliderTimer;
  Timer? _pollingTimer;

  late AnimationController _radarController;
  late AnimationController _pulseController;
  AnimationController? _riderAnimController;

  LatLng? _previousRiderLatLng;
  LatLng? _currentRiderLatLng;
  double _previousRiderRotation = 0.0;
  double _targetRiderRotation = 0.0;

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  static const LatLng _defaultMapCenter = LatLng(22.7196, 75.8577); // Indore fallback

  List<String> _getSliderTexts(AppLocalizations l10n) => [
        l10n.bookingCreatedNotifying,
        l10n.nearestRidersGetting,
        l10n.firstRiderToAccept,
        l10n.broadcastedToNearby,
      ];

  static const Set<String> _searchStatuses = {'REQUESTED', 'SEARCHING'};
  static const Set<String> _terminalStatuses = {'DELIVERED', 'CANCELLED'};
  static const Set<String> _postPickupStatuses = {
    'PICKED_UP',
    'OUT_FOR_DELIVERY',
    'DELIVERED',
  };

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/parcel/outstation');
    }
  }

  @override
  void initState() {
    super.initState();

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _riderAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addListener(() {
        if (mounted) {
          _updateMapElements();
        }
      });

    _sliderTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (mounted) {
        setState(() {
          _sliderIndex = (_sliderIndex + 1) % 4;
        });
      }
    });

    _loadParcel(silent: false);

    // Auto-polling
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      final status = _parcel?['status']?.toString();
      if (status != null && _terminalStatuses.contains(status)) {
        _pollingTimer?.cancel();
        return;
      }
      _loadParcel(silent: true);
    });

    // Socket listener
    _setupSocket();
  }

  void _setupSocket() {
    try {
      _socketService = sl<SocketService>();
      _socketService?.connect();
      _socketService?.on('parcel:status:update', (event) {
        if (!mounted || event == null) return;
        final map = event is Map ? event : {};
        final incomingId =
            map['parcelId']?.toString() ??
            map['parcel']?['_id']?.toString() ??
            map['id']?.toString();
        if (incomingId == widget.parcelId && mounted) {
          _loadParcel(silent: true);
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _pollingTimer?.cancel();
    _socketService?.off('parcel:status:update');
    _radarController.dispose();
    _pulseController.dispose();
    _riderAnimController?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  LatLng? _coordsToLatLng(dynamic coords) {
    if (coords is List && coords.length >= 2) {
      final lng = (coords[0] as num?)?.toDouble();
      final lat = (coords[1] as num?)?.toDouble();
      if (lat != null && lng != null && lat.isFinite && lng.isFinite) {
        return LatLng(lat, lng);
      }
    }
    return null;
  }

  LatLng? _getPickupLatLng() {
    final addr = _parcel?['pickupAddress'];
    if (addr is Map) {
      final lat = (addr['lat'] as num?)?.toDouble() ??
          (addr['latitude'] as num?)?.toDouble();
      final lng = (addr['lng'] as num?)?.toDouble() ??
          (addr['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null && lat.isFinite && lng.isFinite) {
        return LatLng(lat, lng);
      }
      if (addr['location'] is Map) {
        return _coordsToLatLng(addr['location']['coordinates']);
      }
    }
    return null;
  }

  LatLng? _getRiderLatLng() {
    final riderObj = _parcel?['deliveryPartnerId'];
    if (riderObj is Map) {
      final loc = riderObj['location'];
      if (loc is Map) {
        final coords = loc['coordinates'];
        final latLng = _coordsToLatLng(coords);
        if (latLng != null) return latLng;
      }
      final lat = (riderObj['lat'] as num?)?.toDouble();
      final lng = (riderObj['lng'] as num?)?.toDouble();
      if (lat != null && lng != null && lat.isFinite && lng.isFinite) {
        return LatLng(lat, lng);
      }
    }
    final riderLoc = _parcel?['riderLocation'];
    if (riderLoc is Map) {
      final lat = (riderLoc['lat'] as num?)?.toDouble();
      final lng = (riderLoc['lng'] as num?)?.toDouble();
      if (lat != null && lng != null && lat.isFinite && lng.isFinite) {
        return LatLng(lat, lng);
      }
    }
    return null;
  }

  double? _calculateDistanceMeters(LatLng? from, LatLng? to) {
    if (from == null || to == null) return null;
    const double r = 6371000;
    final double dLat = (to.latitude - from.latitude) * (math.pi / 180.0);
    final double dLng = (to.longitude - from.longitude) * (math.pi / 180.0);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(from.latitude * (math.pi / 180.0)) *
            math.cos(to.latitude * (math.pi / 180.0)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  String? _formatDistanceAway(double? meters) {
    if (meters == null || meters < 0 || !meters.isFinite) return null;
    if (meters < 1000) {
      return '${meters.round()} m away';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  void _updateMapElements() {
    final pickup = _getPickupLatLng();
    final rider = _getRiderLatLng();
    final status = _parcel?['status']?.toString() ?? 'SEARCHING';
    final isPostPickup = _postPickupStatuses.contains(status);
    final isTerminal = _terminalStatuses.contains(status);
    final trackingActive = !isPostPickup && !isTerminal;

    final markers = <Marker>{};
    final polylines = <Polyline>{};

    final pickupAddressObj = _parcel?['pickupAddress'];
    final pickupAddress = pickupAddressObj is Map
        ? (pickupAddressObj['fullAddress']?.toString() ?? 'Pickup location')
        : 'Pickup location';

    final riderObj = _parcel?['deliveryPartnerId'];
    final riderName = riderObj is Map ? riderObj['name']?.toString() : null;

    if (pickup != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup_point'),
          position: pickup,
          infoWindow: InfoWindow(
            title: 'Your Pickup Point',
            snippet: pickupAddress,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }

    if (rider != null && trackingActive) {
      if (_previousRiderLatLng == null) {
        _previousRiderLatLng = rider;
        _currentRiderLatLng = rider;
      } else if (_currentRiderLatLng != rider) {
        _previousRiderLatLng = _currentRiderLatLng;
        _currentRiderLatLng = rider;
        if (_previousRiderLatLng != null && _currentRiderLatLng != null) {
          _previousRiderRotation = _targetRiderRotation;
          _targetRiderRotation = MapsService.calculateBearing(
            _previousRiderLatLng!,
            _currentRiderLatLng!,
          );
        }
        _riderAnimController?.forward(from: 0.0);
      }

      LatLng animatedRiderPos = rider;
      double animatedRotation = _targetRiderRotation;

      if (_riderAnimController != null &&
          _riderAnimController!.isAnimating &&
          _previousRiderLatLng != null &&
          _currentRiderLatLng != null) {
        final t = Curves.easeInOut.transform(_riderAnimController!.value);
        animatedRiderPos = MapsService.lerpLatLng(
          _previousRiderLatLng!,
          _currentRiderLatLng!,
          t,
        );
        animatedRotation = _previousRiderRotation +
            (_targetRiderRotation - _previousRiderRotation) * t;
      }

      final meters = _calculateDistanceMeters(animatedRiderPos, pickup);
      final awayText = _formatDistanceAway(meters);

      markers.add(
        Marker(
          markerId: const MarkerId('rider_point'),
          position: animatedRiderPos,
          rotation: animatedRotation,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: riderName != null ? 'Captain: $riderName' : 'Delivery Captain',
            snippet: awayText != null ? 'Coming to you · $awayText' : 'On the way to pickup',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );

      if (pickup != null) {
        List<LatLng> polylinePoints = [rider, pickup];
        final rawPolyline = _parcel?['polyline']?.toString() ??
            _parcel?['routePolyline']?.toString() ??
            (_parcel?['route'] is Map ? _parcel!['route']['polyline']?.toString() : null);

        if (rawPolyline != null && rawPolyline.isNotEmpty) {
          final decoded = MapsService.decodePolyline(rawPolyline);
          if (decoded.isNotEmpty) {
            polylinePoints = decoded;
          }
        }

        polylines.add(
          Polyline(
            polylineId: const PolylineId('route_to_pickup'),
            points: polylinePoints,
            color: const Color(0xFF2563EB),
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _markers = markers;
        _polylines = polylines;
      });
    }

    _fitMapBounds();
  }

  void _fitMapBounds() {
    if (_mapController == null) return;
    final pickup = _getPickupLatLng();
    final rider = _getRiderLatLng();
    final status = _parcel?['status']?.toString() ?? 'SEARCHING';
    final trackingActive =
        !_postPickupStatuses.contains(status) && !_terminalStatuses.contains(status);

    if (pickup != null && rider != null && trackingActive) {
      final southwestLat = math.min(pickup.latitude, rider.latitude);
      final southwestLng = math.min(pickup.longitude, rider.longitude);
      final northeastLat = math.max(pickup.latitude, rider.latitude);
      final northeastLng = math.max(pickup.longitude, rider.longitude);

      final bounds = LatLngBounds(
        southwest: LatLng(southwestLat, southwestLng),
        northeast: LatLng(northeastLat, northeastLng),
      );
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 70.0),
      );
    } else if (pickup != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(pickup, 15.5),
      );
    }
  }

  Future<void> _loadParcel({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    try {
      final res = await _client.get(
        ApiEndpoints.outstationParcelTrack(widget.parcelId),
      );
      if (mounted) {
        final data = res is Map ? (res['result'] ?? res['data'] ?? res) : null;
        if (data is Map) {
          setState(() {
            _parcel = Map<String, dynamic>.from(data);
            _isLoading = false;
          });
          _updateMapElements();
          _maybeLoadMyReview();
        } else if (!silent) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
        AppSnackBar.showOffline(context);
      }
    }
  }

  /// Reads this customer's own review once, and only for a delivered parcel.
  Future<void> _maybeLoadMyReview() async {
    if (_reviewChecked) return;
    final status = _parcel?['status']?.toString();
    if (status != 'DELIVERED') return;

    _reviewChecked = true;
    try {
      final res = await _client.get(
        ApiEndpoints.outstationParcelMyReview(widget.parcelId),
      );
      // The endpoint answers with the review, or null when there is none.
      if (res is Map && res['rating'] != null && mounted) {
        setState(() {
          _hasReviewed = true;
          _existingRating = (res['rating'] as num).toInt();
        });
      }
    } catch (_) {
      // Not fatal — the rating prompt just stays available.
    }
  }

  Future<void> _openRatingSheet() async {
    final submitted = await ParcelRatingSheet.show(
      context,
      parcelId: widget.parcelId,
    );
    if (submitted && mounted) {
      setState(() => _hasReviewed = true);
      _reviewChecked = false;
      _maybeLoadMyReview();
    }
  }

  /// Rating prompt for a completed delivery, or a read-back of the rating
  /// already given.
  Widget _buildRatingPrompt() {
    if (_parcel?['status']?.toString() != 'DELIVERED') {
      return const SizedBox.shrink();
    }

    if (_hasReviewed) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 18.0,
              color: Color(0xFF059669),
            ),
            const SizedBox(width: 10.0),
            const Expanded(
              child: Text(
                'You rated this delivery',
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < _existingRating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 15.0,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How was this delivery?',
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4.0),
          const Text(
            'Rate it so other customers know what to expect.',
            style: TextStyle(fontSize: 12.0, color: Color(0xFF78716C)),
          ),
          const SizedBox(height: 12.0),
          SizedBox(
            width: double.infinity,
            height: 42.0,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onPressed: _openRatingSheet,
              icon: const Icon(Icons.star_rounded, size: 17.0),
              label: const Text(
                'RATE THIS DELIVERY',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancelSearch() async {
    if (_isCancelling || _parcel == null) return;
    setState(() => _isCancelling = true);
    try {
      final res = await _client.post(
        ApiEndpoints.outstationParcelCancel(widget.parcelId),
      );
      if (mounted) {
        final data = res is Map ? (res['result'] ?? res['data'] ?? res) : null;
        if (data is Map) {
          _parcel = Map<String, dynamic>.from(data);
        }
        AppSnackBar.showSuccess(context, AppLocalizations.of(context)!.searchCancelledSuccess);
        _handleBack();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, AppLocalizations.of(context)!.unableToCancelSearch);
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Future<void> _handleRequestLateRefund() async {
    if (_isRequestingLateRefund || _parcel == null) return;
    setState(() => _isRequestingLateRefund = true);
    try {
      final res = await _client.post(
        ApiEndpoints.outstationParcelLateRefund(widget.parcelId),
        data: {'reason': 'Normal pickup exceeded 30 minutes'},
      );
      if (mounted) {
        final data = res is Map ? (res['result'] ?? res['data'] ?? res) : null;
        if (data is Map) {
          _parcel = Map<String, dynamic>.from(data);
        }
        AppSnackBar.showSuccess(
          context,
          AppLocalizations.of(context)!.lateRefundRequestSent,
        );
        _loadParcel(silent: true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, AppLocalizations.of(context)!.unableToRequestRefund);
      }
    } finally {
      if (mounted) setState(() => _isRequestingLateRefund = false);
    }
  }

  String _formatStatusLabel(BuildContext context, String status) {
    final parcelStatus = ParcelStatus.fromString(status);
    return parcelStatus.getLocalizedLabel(context);
  }

  Map<String, String?> _getStatusUi(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'ACCEPTED':
      case 'RIDER_ASSIGNED':
        return {
          'title': l10n.captainAssigned,
          'subtitle': l10n.captainOnWayToPickup,
        };
      case 'PICKUP_REACHED':
        return {
          'title': l10n.captainAtPickup,
          'subtitle': l10n.riderReachedPickup,
        };
      case 'PICKED_UP':
        return {
          'title': l10n.parcelCollected,
          'subtitle': l10n.captainCollectedParcel,
        };
      case 'OUT_FOR_DELIVERY':
        return {
          'title': l10n.parcelCollected,
          'subtitle': l10n.parcelWithCaptain,
        };
      case 'DELIVERED':
        return {
          'title': l10n.completed,
          'subtitle': l10n.parcelRequestComplete,
        };
      case 'CANCELLED':
        return {
          'title': l10n.cancelled,
          'subtitle': l10n.parcelRequestCancelled,
        };
      default:
        return {
          'title': l10n.findingDeliveryCaptain,
          'subtitle': null,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _parcel == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEA580C)),
              ),
              SizedBox(height: 14.0),
              Text(
                'Loading tracking...',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final status = _parcel!['status']?.toString() ?? 'SEARCHING';
    final isSearching =
        _searchStatuses.contains(status) &&
        _parcel!['deliveryPartnerId'] == null;
    final statusUi = _getStatusUi(context, status);

    final pickupAddressObj = _parcel!['pickupAddress'];
    final pickupFullAddress = pickupAddressObj is Map
        ? (pickupAddressObj['fullAddress']?.toString() ?? '')
        : '';

    final fare = (_parcel!['fare'] as num?)?.toDouble() ?? 0.0;
    final distance = (_parcel!['distance'] as num?)?.toDouble() ?? 0.0;
    final otp = _parcel!['otp']?.toString() ?? '';

    final riderObj = _parcel!['deliveryPartnerId'];
    final riderMap = riderObj is Map
        ? Map<String, dynamic>.from(riderObj)
        : null;
    final riderName = riderMap?['name']?.toString();
    final riderPhone = riderMap?['phone']?.toString();
    final riderVehicle = riderMap?['vehicleNumber']?.toString() ??
        riderMap?['vehicleType']?.toString();

    final pickupSlaObj = _parcel!['pickupSla'];
    final pickupSlaMap = pickupSlaObj is Map ? pickupSlaObj : null;
    final canRequestLateRefund =
        pickupSlaMap?['canRequestLateRefund'] == true;

    final lateRefundObj = _parcel!['lateRefundRequest'];
    final lateRefundMap = lateRefundObj is Map ? lateRefundObj : null;
    final lateRefundStatus = lateRefundMap?['status']?.toString();
    final approvedAmount =
        (lateRefundMap?['approvedAmount'] as num?)?.toDouble() ?? 0.0;

    final pickupPoint = _getPickupLatLng() ?? _defaultMapCenter;
    final riderPoint = _getRiderLatLng();
    final isPostPickup = _postPickupStatuses.contains(status);
    final isTerminal = _terminalStatuses.contains(status);
    final trackingActive = !isPostPickup && !isTerminal;

    final captainAwayMeters = (riderPoint != null && trackingActive)
        ? _calculateDistanceMeters(riderPoint, pickupPoint)
        : null;
    final captainAwayText = _formatDistanceAway(captainAwayMeters);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // 1. Full-screen Real Google Map
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: pickupPoint,
                zoom: 15.0,
              ),
              style: '''[
                {
                  "featureType": "poi",
                  "elementType": "all",
                  "stylers": [
                    { "visibility": "off" }
                  ]
                },
                {
                  "featureType": "transit",
                  "elementType": "all",
                  "stylers": [
                    { "visibility": "simplified" }
                  ]
                }
              ]''',
              onMapCreated: (controller) {
                _mapController = controller;
                _updateMapElements();
              },
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              trafficEnabled: false,
              buildingsEnabled: true,
            ),
          ),

          // 2. Centered Radar Pulse Animation (While Searching)
          if (isSearching)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.25,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: _buildRadarAnimation(),
                ),
              ),
            ),

          // 3. Floating Glassmorphic Top Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10.0,
            left: 16.0,
            right: 16.0,
            child: _buildFloatingTopBar(
              status: status,
              isSearching: isSearching,
              pickupFullAddress: pickupFullAddress,
              riderName: riderName,
              captainAwayText: captainAwayText,
            ),
          ),

          // 4. Draggable Bottom Sheet
          _buildDraggableBottomSheet(
            status: status,
            isSearching: isSearching,
            statusUi: statusUi,
            fare: fare,
            distance: distance,
            otp: otp,
            riderName: riderName,
            riderPhone: riderPhone,
            riderVehicle: riderVehicle,
            canRequestLateRefund: canRequestLateRefund,
            lateRefundStatus: lateRefundStatus,
            approvedAmount: approvedAmount,
            captainAwayText: captainAwayText,
            trackingActive: trackingActive,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Floating Bar
  // ---------------------------------------------------------------------------
  Widget _buildFloatingTopBar({
    required String status,
    required bool isSearching,
    required String pickupFullAddress,
    required String? riderName,
    required String? captainAwayText,
  }) {
    final l10n = AppLocalizations.of(context)!;
    Color badgeBg = const Color(0xFFEFF6FF);
    Color badgeText = const Color(0xFF2563EB);

    if (status == 'DELIVERED') {
      badgeBg = const Color(0xFFECFDF5);
      badgeText = const Color(0xFF059669);
    } else if (status == 'CANCELLED') {
      badgeBg = const Color(0xFFFEF2F2);
      badgeText = const Color(0xFFDC2626);
    } else if (isSearching) {
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = const Color(0xFFD97706);
    }

    final isPostPickup = _postPickupStatuses.contains(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 16.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  riderName != null && !isPostPickup
                      ? l10n.liveTracking
                      : isPostPickup
                          ? l10n.trackingEnded
                          : l10n.parcelPickup,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  riderName != null && !isPostPickup && captainAwayText != null
                      ? l10n.captainIsDistanceAway(captainAwayText)
                      : riderName != null && !isPostPickup
                          ? l10n.captainIsOnWay
                          : isPostPickup
                              ? l10n.parcelHandedToCaptain
                              : (pickupFullAddress.isNotEmpty
                                  ? pickupFullAddress
                                  : l10n.pickupLocation),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9.0,
              vertical: 4.5,
            ),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: Text(
              _formatStatusLabel(context, status),
              style: TextStyle(
                fontSize: 10.0,
                fontWeight: FontWeight.w800,
                color: badgeText,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 6.0),
          GestureDetector(
            onTap: _handleBack,
            child: Container(
              width: 34.0,
              height: 34.0,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 18.0,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Radar Wave Animation
  // ---------------------------------------------------------------------------
  Widget _buildRadarAnimation() {
    return AnimatedBuilder(
      animation: _radarController,
      builder: (context, child) {
        final t = _radarController.value;
        return SizedBox(
          width: 140.0,
          height: 140.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer expanding ring 1
              Container(
                width: 70.0 + (70.0 * t),
                height: 70.0 + (70.0 * t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEA580C)
                      .withValues(alpha: (1.0 - t) * 0.28),
                ),
              ),
              // Ring 2
              Container(
                width: 90.0,
                height: 90.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
              ),
              // Ring 3
              Container(
                width: 60.0,
                height: 60.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.65),
                    width: 1.2,
                  ),
                ),
              ),
              // Rotating satellite blip
              Transform.rotate(
                angle: t * 2 * math.pi,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 12.0,
                    height: 12.0,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC2410C),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x66C2410C),
                          blurRadius: 6.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Center orange pulsing dot
              Container(
                width: 24.0,
                height: 24.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40EA580C),
                      blurRadius: 10.0,
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Draggable Bottom Sheet
  // ---------------------------------------------------------------------------
  Widget _buildDraggableBottomSheet({
    required String status,
    required bool isSearching,
    required Map<String, String?> statusUi,
    required double fare,
    required double distance,
    required String otp,
    required String? riderName,
    required String? riderPhone,
    required String? riderVehicle,
    required bool canRequestLateRefund,
    required String? lateRefundStatus,
    required double approvedAmount,
    required String? captainAwayText,
    required bool trackingActive,
  }) {
    return DraggableScrollableSheet(
      initialChildSize: isSearching ? 0.48 : 0.58,
      minChildSize: 0.36,
      maxChildSize: 0.88,
      snap: true,
      snapSizes: const [0.36, 0.58, 0.88],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28.0),
            ),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x200F172A),
                blurRadius: 32.0,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 24.0),
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44.0,
                  height: 5.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3.0),
                  ),
                ),
              ),
              const SizedBox(height: 6.0),
              const Center(
                child: Text(
                  'Swipe up / down',
                  style: TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              const SizedBox(height: 14.0),

              // Rating prompt for a completed delivery — sits above the fold
              // so it is the first thing a customer sees once it is done.
              _buildRatingPrompt(),

              // Title
              Text(
                statusUi['title'] ?? 'Finding your delivery captain',
                style: const TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4.0),

              // Subtitle ticker / description
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  isSearching
                      ? _getSliderTexts(AppLocalizations.of(context)!)[
                          _sliderIndex % 4]
                      : (statusUi['subtitle'] ?? ''),
                  key: ValueKey(
                    isSearching
                        ? _sliderIndex
                        : (statusUi['subtitle'] ?? ''),
                  ),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ),

              const SizedBox(height: 16.0),

              // SEARCHING VIEW vs ASSIGNED / COMPLETED VIEW
              if (isSearching) ...[
                // Expected Price Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14.0,
                    horizontal: 16.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(18.0),
                    border: Border.all(color: const Color(0xFFFEF3C7)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'EXPECTED PRICE',
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFB45309),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        '₹${fare.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Estimated for about ${distance.toStringAsFixed(1)} km.',
                        style: const TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14.0),

                // Pagination Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (idx) {
                    final isActive = idx == _sliderIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3.5),
                      width: isActive ? 10.0 : 8.0,
                      height: isActive ? 10.0 : 8.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? const Color(0xFFEA580C)
                            : const Color(0xFFCBD5E1),
                        boxShadow: isActive
                            ? const [
                                BoxShadow(
                                  color: Color(0x40EA580C),
                                  blurRadius: 6.0,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16.0),

                // Feature Badges
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Row(
                        children: [
                          Icon(
                            Icons.bolt,
                            size: 16.0,
                            color: Color(0xFF10B981),
                          ),
                          SizedBox(width: 6.0),
                          Text(
                            'FAST DISPATCH',
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF334155),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 16.0,
                            color: Color(0xFF2563EB),
                          ),
                          SizedBox(width: 6.0),
                          Text(
                            'PARCEL SAFETY',
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF334155),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18.0),

                // Cancel Search Button
                SizedBox(
                  width: double.infinity,
                  height: 48.0,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    onPressed: _isCancelling ? null : _handleCancelSearch,
                    child: _isCancelling
                        ? const SizedBox(
                            width: 20.0,
                            height: 20.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'CANCEL',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                  ),
                ),
              ] else ...[
                // ASSIGNED / IN TRANSIT / DELIVERED
                // Fare & Trip Distance Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FARE',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3.0),
                          Text(
                            '₹${fare.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            trackingActive && captainAwayText != null
                                ? 'CAPTAIN DISTANCE'
                                : 'TRIP DISTANCE',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3.0),
                          Text(
                            trackingActive && captainAwayText != null
                                ? captainAwayText
                                : '${distance.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12.0),

                // Delivery Captain Card
                if (riderName != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18.0),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x060F172A),
                          blurRadius: 10.0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44.0,
                          height: 44.0,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 22.0,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DELIVERY CAPTAIN',
                                style: TextStyle(
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                riderName,
                                style: const TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              if (trackingActive && captainAwayText != null) ...[
                                const SizedBox(height: 2.0),
                                Text(
                                  'Coming to you · $captainAwayText',
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    color: Color(0xFFEA580C),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ] else if (riderVehicle != null) ...[
                                const SizedBox(height: 2.0),
                                Text(
                                  riderVehicle,
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (riderPhone != null && riderPhone.isNotEmpty)
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: const BoxDecoration(
                                color: Color(0xFFECFDF5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.phone,
                                size: 18.0,
                                color: Color(0xFF059669),
                              ),
                            ),
                            onPressed: () => launchUrl(
                              Uri.parse('tel:$riderPhone'),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12.0),
                ],

                // Pickup OTP Box
                if (otp.isNotEmpty &&
                    !_postPickupStatuses.contains(status)) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14.0,
                      horizontal: 16.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(18.0),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'PICKUP OTP',
                          style: TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF059669),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          otp,
                          style: const TextStyle(
                            fontSize: 32.0,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF065F46),
                            letterSpacing: 8.0,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        const Text(
                          'Share this OTP only with your delivery captain when they collect the parcel.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12.0),
                ],

                // Late Pickup SLA Box (30 min)
                if (canRequestLateRefund ||
                    lateRefundStatus == 'requested' ||
                    lateRefundStatus == 'approved' ||
                    lateRefundStatus == 'rejected') ...[
                  Container(
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LATE PICKUP (NORMAL 30 MIN)',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF92400E),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        if (lateRefundStatus == 'requested')
                          const Text(
                            'Refund request is pending admin review. COD / fare collection stays unchanged until then.',
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF78350F),
                            ),
                          )
                        else if (lateRefundStatus == 'approved')
                          Text(
                            'Admin credited ₹${approvedAmount.toStringAsFixed(2)} to your wallet.',
                            style: const TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF065F46),
                            ),
                          )
                        else if (lateRefundStatus == 'rejected')
                          const Text(
                            'Late refund request was rejected.',
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          )
                        else if (canRequestLateRefund) ...[
                          const Text(
                            'Captain took longer than 30 minutes. You can ask admin for a wallet refund.',
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF78350F),
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD97706),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              onPressed: _isRequestingLateRefund
                                  ? null
                                  : _handleRequestLateRefund,
                              child: _isRequestingLateRefund
                                  ? const Text('Submitting...')
                                  : const Text(
                                      'REQUEST LATE REFUND',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12.0),
                ],

                const SizedBox(height: 8.0),

                // Open Parcel History Button
                SizedBox(
                  width: double.infinity,
                  height: 48.0,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    onPressed: () => context.push('/profile/parcel-history'),
                    child: Text(
                      _terminalStatuses.contains(status)
                          ? 'BACK TO PARCEL'
                          : 'OPEN PARCEL HISTORY',
                      style: const TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
