import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sungguard/l10n/app_localizations.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../booking/presentation/widgets/outstation_map_picker_dialog.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/ink_barcode.dart';
import '../../../../core/widgets/perforation_line.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/parcel_detail_entity.dart';
import '../bloc/tracking_bloc.dart';
import '../bloc/tracking_event.dart';
import '../bloc/tracking_state.dart';

class CityParcelTrackingPage extends StatefulWidget {
  final String parcelId;
  final VoidCallback? onBack;

  const CityParcelTrackingPage({super.key, required this.parcelId, this.onBack});

  @override
  State<CityParcelTrackingPage> createState() => _CityParcelTrackingPageState();
}

class _CityParcelTrackingPageState extends State<CityParcelTrackingPage> {
  final ApiClient _client = ApiClient.createDefault();
  Timer? _pollingTimer;
  Timer? _cooldownTimer;

  int _cooldownSeconds = 0;
  String? _handoverCode;
  bool _isRequestingCode = false;

  // Failure response state
  String _selectedFailureChoice = '';
  bool _isSubmittingFailure = false;

  /// Alternate address for the two choices whose schema requires one.
  /// The server rejects RETURN_TO_NEW_ADDRESS and RETRY_NEW_ADDRESS without
  /// it, and forbids it on every other choice — so it is collected only when
  /// one of those two is picked.
  String _newAddressText = '';
  double? _newAddressLat;
  double? _newAddressLng;

  static const Set<String> _choicesNeedingAddress = {
    'RETURN_TO_NEW_ADDRESS',
    'RETRY_NEW_ADDRESS',
  };

  bool get _needsNewAddress =>
      _choicesNeedingAddress.contains(_selectedFailureChoice);

  bool get _newAddressReady =>
      _newAddressText.trim().length >= 5 &&
      _newAddressLat != null &&
      _newAddressLng != null;

  List<Map<String, String>> _getMilestones(AppLocalizations l10n) => [
    {'key': 'REQUESTED', 'label': l10n.milestoneBooked},
    {'key': 'ACCEPTED', 'label': l10n.milestoneRiderAssigned},
    {'key': 'PICKED_UP', 'label': l10n.milestoneCollectedFromYou},
    {'key': 'OUT_FOR_DELIVERY', 'label': l10n.milestoneOnWayToDrop},
    {'key': 'DELIVERED', 'label': l10n.milestoneHandedToReceiver},
  ];

  static const List<String> _statusOrder = [
    'REQUESTED',
    'SEARCHING',
    'ACCEPTED',
    'RIDER_ASSIGNED',
    'PICKUP_REACHED',
    'PICKED_UP',
    'OUT_FOR_DELIVERY',
    'DROP_REACHED',
    'DELIVERED',
  ];

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTracking();

    // Auto-poll every 10 seconds while tracking is active
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      final currentStatus = context.read<TrackingBloc>().state.parcel?.status;
      if (currentStatus != null && !currentStatus.isLive) {
        _pollingTimer?.cancel();
        return;
      }
      context.read<TrackingBloc>().add(TrackingLoadRequested(widget.parcelId));
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _loadTracking() {
    context.read<TrackingBloc>().add(TrackingLoadRequested(widget.parcelId));
  }

  void _startCooldown(int seconds) {
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds -= 1);
      }
    });
  }

  Future<void> _requestCode() async {
    if (_isRequestingCode || _cooldownSeconds > 0) return;
    setState(() => _isRequestingCode = true);
    try {
      final res = await _client.post(ApiEndpoints.cityParcelRequestCode(widget.parcelId));
      final data = res is Map ? (res['result'] ?? res['data'] ?? res) : null;
      if (mounted && data is Map) {
        final code = data['devCode']?.toString() ?? data['code']?.toString() ?? data['otp']?.toString();
        setState(() {
          _handoverCode = code;
        });
        _startCooldown(15);
        final l10n = AppLocalizations.of(context)!;
        final sentTo = data['sentToPhone']?.toString() ?? l10n.phoneNumber;
        AppSnackBar.showSuccess(context, '${l10n.authOtpSentTo} $sentTo');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, AppLocalizations.of(context)!.error);
      }
    } finally {
      if (mounted) setState(() => _isRequestingCode = false);
    }
  }

  Future<void> _submitFailureResponse() async {
    if (_selectedFailureChoice.isEmpty || _isSubmittingFailure) return;
    if (_needsNewAddress && !_newAddressReady) {
      AppSnackBar.showError(
        context,
        'Pick the new address on the map first',
      );
      return;
    }

    setState(() => _isSubmittingFailure = true);
    try {
      await _client.post(
        ApiEndpoints.cityParcelFailureResponse(widget.parcelId),
        data: {
          'choice': _selectedFailureChoice,
          // Required for the two *_NEW_ADDRESS choices and forbidden for the
          // rest, so it is only ever included when the choice calls for it.
          if (_needsNewAddress)
            'newAddress': {
              'fullAddress': _newAddressText.trim(),
              'lat': _newAddressLat,
              'lng': _newAddressLng,
            },
        },
      );
      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          _selectedFailureChoice.startsWith('RETURN')
              ? AppLocalizations.of(context)!.returningToSender
              : AppLocalizations.of(context)!.failOptionTryAgain,
        );
        _loadTracking();
      }
    } catch (e) {
      if (mounted) {
        // The server explains exactly what it refused; a generic toast threw
        // that away.
        AppSnackBar.showError(
          context,
          (e is ApiException && e.message.isNotEmpty)
              ? e.message
              : AppLocalizations.of(context)!.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingFailure = false);
    }
  }

  /// Map picker for the alternate address.
  Future<void> _pickNewAddress() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => OutstationMapPickerDialog(
        initialLat: _newAddressLat ?? 22.7560,
        initialLng: _newAddressLng ?? 75.8657,
        onLocationConfirmed: (lat, lng, address, details) {
          setState(() {
            _newAddressLat = lat;
            _newAddressLng = lng;
            _newAddressText = details?.formattedAddress.isNotEmpty == true
                ? details!.formattedAddress
                : address;
          });
        },
      ),
    );
  }

  String _formatDateTime(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      return DateFormat('d MMM, hh:mm a').format(dt).toLowerCase();
    } catch (_) {
      return rawDate;
    }
  }

  Map<String, dynamic> _getStatusMeta(ParcelStatus status) {
    return {'tone': status.tone, 'label': status.getLocalizedLabel(context)};
  }

  int _getReachedIndex(ParcelStatus status) {
    // `.code`, not `.name`: enum names are camelCase, so `.name.toUpperCase()`
    // produced "OUTFORDELIVERY" and missed every multi-word status in
    // _statusOrder — the timeline sat at zero progress for most of a delivery.
    return _statusOrder.indexOf(status.code);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrackingBloc, TrackingState>(
      listenWhen: (previous, current) =>
          previous.cancelSuccess != current.cancelSuccess ||
          previous.errorMessage != current.errorMessage ||
          previous.parcel?.status != current.parcel?.status,
      listener: (context, state) {
        if (state.cancelSuccess) {
          _pollingTimer?.cancel();
          AppSnackBar.showSuccess(context, AppLocalizations.of(context)!.cancelled);
          _handleBack();
        } else if (state.errorMessage != null) {
          AppSnackBar.showError(context, AppLocalizations.of(context)!.error);
        }

        final currentStatus = state.parcel?.status;
        if (currentStatus != null && !currentStatus.isLive) {
          _pollingTimer?.cancel();
        }
      },
      builder: (context, state) {
        final parcel = state.parcel;

        if (state.isLoading && parcel == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEA580C))),
            ),
          );
        }

        if (parcel == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                onPressed: _handleBack,
              ),
              title: const Text(
                'Tracking',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 17.0),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.couldNotLoadParcel,
                    style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _loadTracking,
                    child: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            ),
          );
        }

        final status = parcel.status;
        final meta = _getStatusMeta(status);
        final rider = parcel.rider;
        final l10n = AppLocalizations.of(context)!;
        final showNote =
            status == ParcelStatus.accepted ||
            status == ParcelStatus.riderAssigned ||
            status == ParcelStatus.pickupReached ||
            status == ParcelStatus.returnInTransit;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 20.0),
              onPressed: _handleBack,
            ),
            centerTitle: true,
            title: Text(
              l10n.trackingTitle,
              style: const TextStyle(fontSize: 17.0, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: StatusChip(label: meta['label'] as String, tone: meta['tone'] as StatusTone),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            color: const Color(0xFFEA580C),
            onRefresh: () async => _loadTracking(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 48.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Failure Prompt (When DELIVERY_FAILED)
                      // 0. An online booking that was never paid for. The
                      // backend keeps it at REQUESTED and dispatches nobody,
                      // so without this the screen just sits at "Awaiting
                      // Pickup" forever with no explanation.
                      if (parcel.awaitingPayment) ...[
                        _buildAwaitingPaymentCard(parcel),
                        const SizedBox(height: 16.0),
                      ],

                      if (status == ParcelStatus.deliveryFailed) ...[
                        _buildFailurePromptCard(parcel, l10n),
                        const SizedBox(height: 16.0),
                      ],

                      // 2. Consignment Note (When ACCEPTED, RIDER_ASSIGNED, PICKUP_REACHED, RETURN_IN_TRANSIT)
                      if (showNote) ...[_buildConsignmentNoteCard(parcel, l10n), const SizedBox(height: 16.0)],

                      // 3. Rider Card
                      if (rider != null) ...[_buildRiderCard(rider), const SizedBox(height: 16.0)],

                      // 4. Route Card
                      _buildRouteCard(parcel, l10n),
                      const SizedBox(height: 16.0),

                      // 5. Progress / Milestones Card
                      _buildMilestonesCard(parcel, l10n),
                      const SizedBox(height: 16.0),

                      // 6. Cancel booking button (When REQUESTED or SEARCHING)
                      if (status == ParcelStatus.requested || status == ParcelStatus.searching) ...[
                        _buildCancelButton(state, l10n),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Consignment Note Card (Exact match to React ConsignmentNote)
  // ---------------------------------------------------------------------------
  Widget _buildConsignmentNoteCard(ParcelDetailEntity parcel, AppLocalizations l10n) {
    final isReturn = parcel.status == ParcelStatus.returnInTransit;
    final effectiveCode = _handoverCode ?? parcel.handoverCode;
    final digits = effectiveCode != null && effectiveCode.isNotEmpty ? effectiveCode.split('') : <String>[];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x080F172A), blurRadius: 16.0, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dark Header — The Consignment Note itself
          Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SunGguard',
                          style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          l10n.consignmentNoteTitle,
                          style: AppTypography.monoLabel.copyWith(
                            fontSize: 11.0,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        l10n.copyOne,
                        style: AppTypography.monoLabel.copyWith(
                          fontSize: 10.0,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Text(
                  parcel.referenceId,
                  style: const TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.yourNumber,
                      style: AppTypography.monoLabel.copyWith(
                        fontSize: 11.0,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                    Text(
                      l10n.verified,
                      style: AppTypography.monoLabel.copyWith(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Perforation Dashed Line
          const PerforationLine(color: Color(0xFFCBD5E1), dashWidth: 6.0, dashGap: 4.0, height: 1.5),

          // Light Body — The Code & Action
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReturn ? l10n.codeToTakeBack : l10n.codeForRider,
                  style: const TextStyle(fontSize: 17.0, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '${l10n.authOtpSentTo} ${parcel.senderPhone.isNotEmpty ? parcel.senderPhone : l10n.phoneNumber}',
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16.0),

                // Digits Display or Explanation Note
                if (digits.isNotEmpty)
                  Row(
                    children: digits.map((d) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          height: 56.0,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: const Color(0xFFFFEDD5)),
                          ),
                          child: Text(
                            d,
                            style: const TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      l10n.tapCodeInstructions,
                      style: const TextStyle(fontSize: 13.0, color: Color(0xFF475569), height: 1.35),
                    ),
                  ),

                const SizedBox(height: 16.0),

                // Send / Resend Code Button
                SizedBox(
                  width: double.infinity,
                  height: 48.0,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                      disabledBackgroundColor: const Color(0xFFEA580C).withValues(alpha: 0.4),
                    ),
                    onPressed: _isRequestingCode || _cooldownSeconds > 0 ? null : _requestCode,
                    child: _isRequestingCode
                        ? const SizedBox(
                            width: 20.0,
                            height: 20.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.refresh, size: 16.0),
                              const SizedBox(width: 6.0),
                              Text(
                                _cooldownSeconds > 0 ? l10n.resendInSeconds(_cooldownSeconds) : l10n.sendMeCode,
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20.0),

                // Barcode + Caption
                Center(
                  child: Column(
                    children: [
                      InkBarcode(seed: parcel.referenceId, height: 38.0, color: const Color(0xFF0F172A)),
                      const SizedBox(height: 8.0),
                      Text(
                        isReturn ? l10n.returningToSender : l10n.awaitingPickupVerification,
                        style: AppTypography.monoLabel.copyWith(fontSize: 10.5, color: const Color(0xFF64748B)),
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

  // ---------------------------------------------------------------------------
  // 2. Failure Prompt Card (When DELIVERY_FAILED)
  // ---------------------------------------------------------------------------
  /// Explains a booking stuck behind an unconfirmed online payment.
  Widget _buildAwaitingPaymentCard(ParcelDetailEntity parcel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFFDBA74)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                size: 20.0,
                color: Color(0xFFEA580C),
              ),
              const SizedBox(width: 10.0),
              const Expanded(
                child: Text(
                  'Waiting for payment',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            'This booking was created with ${parcel.paymentMethod.isNotEmpty ? parcel.paymentMethod : 'an online method'} '
            'but the payment was not completed, so no rider has been assigned yet. '
            'Book again and pay to confirm, or cancel this one.',
            style: const TextStyle(
              fontSize: 12.8,
              color: Color(0xFF9A3412),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14.0),
          SizedBox(
            width: double.infinity,
            height: 44.0,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onPressed: () => context.go('/parcel/local'),
              child: const Text(
                'BOOK AGAIN',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailurePromptCard(ParcelDetailEntity parcel, AppLocalizations l10n) {
    final options = [
      {
        'value': 'RETRY_SAME',
        'label': l10n.failOptionTryAgain,
        'hint': l10n.failOptionTryAgainHint,
        'icon': Icons.replay,
      },
      {
        'value': 'RELEASE_TO_ANYONE',
        'label': l10n.failOptionRelease,
        'hint': l10n.failOptionReleaseHint,
        'icon': Icons.check_circle_outline,
      },
      {
        'value': 'RETURN_TO_PICKUP',
        'label': l10n.failOptionReturn,
        'hint': l10n.failOptionReturnHint,
        'icon': Icons.home_outlined,
      },
      // Both of these were supported by the API from the start and had no UI.
      {
        'value': 'RETRY_NEW_ADDRESS',
        'label': 'Try a different address',
        'hint': 'Send it to another address today',
        'icon': Icons.edit_location_alt_outlined,
      },
      {
        'value': 'RETURN_TO_NEW_ADDRESS',
        'label': 'Return it somewhere else',
        'hint': 'Bring it back to an address that suits you',
        'icon': Icons.assistant_direction_outlined,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        boxShadow: const [BoxShadow(color: Color(0x0A0F172A), blurRadius: 16.0, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24.0),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.weCouldNotHandOver,
                      style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      l10n.deliveryFailedPromptDesc,
                      style: const TextStyle(fontSize: 13.0, color: Color(0xFF475569), height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Options List
          ...options.map((option) {
            final value = option['value'] as String;
            final label = option['label'] as String;
            final hint = option['hint'] as String;
            final icon = option['icon'] as IconData;
            final isSelected = _selectedFailureChoice == value;

            return GestureDetector(
              onTap: () => setState(() => _selectedFailureChoice = value),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8.0),
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 20.0, color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF94A3B8)),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(hint, style: const TextStyle(fontSize: 12.0, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          if (_needsNewAddress) ...[
            const SizedBox(height: 4.0),
            GestureDetector(
              onTap: _pickNewAddress,
              child: Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                    color: _newAddressReady
                        ? const Color(0xFF059669)
                        : const Color(0xFFCBD5E1),
                    width: _newAddressReady ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _newAddressReady
                          ? Icons.check_circle_outline
                          : Icons.map_outlined,
                      size: 20.0,
                      color: _newAddressReady
                          ? const Color(0xFF059669)
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Text(
                        _newAddressReady
                            ? _newAddressText
                            : 'Pick the new address on the map',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: _newAddressReady
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20.0,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12.0),

          // Confirm Button
          SizedBox(
            width: double.infinity,
            height: 46.0,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                disabledBackgroundColor: const Color(0xFFEA580C).withValues(alpha: 0.4),
              ),
              onPressed: (_selectedFailureChoice.isEmpty ||
                      _isSubmittingFailure ||
                      (_needsNewAddress && !_newAddressReady))
                  ? null
                  : _submitFailureResponse,
              child: _isSubmittingFailure
                  ? const SizedBox(
                      width: 20.0,
                      height: 20.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(l10n.confirm, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Rider Card
  // ---------------------------------------------------------------------------
  Widget _buildRiderCard(RiderInfoEntity rider) {
    final vehicle = rider.vehicleNumber ?? rider.vehicleType ?? 'Delivery partner';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 12.0, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 44.0,
            height: 44.0,
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: const Icon(Icons.pin_drop_outlined, size: 22.0, color: Color(0xFF0F172A)),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rider.name,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2.0),
                Text(vehicle, style: const TextStyle(fontSize: 12.0, color: Color(0xFF64748B))),
              ],
            ),
          ),
          if (rider.phone.isNotEmpty)
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('tel:${rider.phone}')),
              child: Container(
                width: 40.0,
                height: 40.0,
                decoration: const BoxDecoration(color: Color(0xFFEA580C), shape: BoxShape.circle),
                child: const Icon(Icons.phone, size: 18.0, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Route Card
  // ---------------------------------------------------------------------------
  Widget _buildRouteCard(ParcelDetailEntity parcel, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 12.0, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.routeTitle,
            style: AppTypography.monoLabel.copyWith(fontSize: 11.0, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 14.0),

          // From
          Text(l10n.routeFrom, style: AppTypography.monoLabel.copyWith(fontSize: 10.0, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 2.0),
          Text(
            parcel.pickupAddress,
            style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: Color(0xFF0F172A), height: 1.3),
          ),

          const SizedBox(height: 14.0),

          // To
          Text(l10n.routeTo, style: AppTypography.monoLabel.copyWith(fontSize: 10.0, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 2.0),
          Text(
            parcel.dropAddress,
            style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: Color(0xFF0F172A), height: 1.3),
          ),

          const SizedBox(height: 16.0),
          const Divider(color: Color(0xFFF1F5F9), height: 1.0),
          const SizedBox(height: 14.0),

          // Receiver & Fare
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.receiver,
                    style: AppTypography.monoLabel.copyWith(fontSize: 10.0, color: const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    parcel.receiverName,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.fare,
                    style: AppTypography.monoLabel.copyWith(fontSize: 10.0, color: const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    '₹${parcel.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Progress / Milestones Card
  // ---------------------------------------------------------------------------
  Widget _buildMilestonesCard(ParcelDetailEntity parcel, AppLocalizations l10n) {
    final reachedIndex = _getReachedIndex(parcel.status);
    final milestones = _getMilestones(l10n);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 12.0, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.progressTitle,
            style: AppTypography.monoLabel.copyWith(fontSize: 11.0, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 16.0),

          // Milestone list
          ...milestones.asMap().entries.map((entry) {
            final index = entry.key;
            final milestone = entry.value;
            final key = milestone['key']!;
            final label = milestone['label']!;
            final isLast = index == milestones.length - 1;

            final milestoneOrderIndex = _statusOrder.indexOf(key);
            final isDone = reachedIndex >= milestoneOrderIndex && reachedIndex >= 0;

            // Find timeline timestamp event
            TrackingTimelineEventEntity? event;
            for (final e in parcel.timeline) {
              if (e.status.toUpperCase() == key) {
                event = e;
                break;
              }
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicator dot & connecting line
                  SizedBox(
                    width: 24.0,
                    child: Column(
                      children: [
                        if (isDone)
                          const Icon(Icons.check_circle, size: 18.0, color: Color(0xFFEA580C))
                        else
                          Container(
                            width: 16.0,
                            height: 16.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFCBD5E1), width: 2.0),
                            ),
                          ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 1.5,
                              color: isDone ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12.0),

                  // Label and timestamp
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w700,
                              color: isDone ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                            ),
                          ),
                          if (event?.at != null) ...[
                            const SizedBox(height: 2.0),
                            Text(
                              _formatDateTime(event!.at),
                              style: AppTypography.monoLabel.copyWith(fontSize: 11.0, color: const Color(0xFF94A3B8)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Cancel Booking Button
  // ---------------------------------------------------------------------------
  Widget _buildCancelButton(TrackingState state, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 48.0,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          foregroundColor: const Color(0xFF64748B),
        ),
        onPressed: state.isCancelling
            ? null
            : () {
                context.read<TrackingBloc>().add(TrackingCancelRequested(widget.parcelId));
              },
        child: state.isCancelling
            ? const SizedBox(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
                ),
              )
            : Text(
                l10n.cancelThisBooking,
                style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
              ),
      ),
    );
  }
}
