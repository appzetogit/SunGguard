import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/services/socket_service.dart';

import '../../domain/repositories/tracking_repository.dart';
import 'tracking_event.dart';
import 'tracking_state.dart';

class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final TrackingRepository trackingRepository;
  final SocketService socketService;

  TrackingBloc({
    required this.trackingRepository,
    required this.socketService,
  }) : super(const TrackingState()) {
    on<TrackingLoadRequested>(_onLoadRequested);
    on<TrackingRequestOtpRequested>(_onRequestOtpRequested);
    on<TrackingStatusUpdatedFromSocket>(_onStatusUpdatedFromSocket);
    on<TrackingCancelRequested>(_onCancelRequested);
  }

  Future<void> _onLoadRequested(
    TrackingLoadRequested event,
    Emitter<TrackingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null, cancelSuccess: false));
    try {
      final parcel = await trackingRepository.getParcelDetails(event.parcelId);
      emit(state.copyWith(
        isLoading: false,
        cancelSuccess: false,
        parcel: parcel,
        otpCode: parcel.handoverCode,
      ));

      // Real-time updates. `connect()` must be awaited: it reads the auth
      // token asynchronously before the socket exists, so registering
      // handlers against a fire-and-forget connect attached them to nothing.
      await socketService.connect();

      // Clear first — this handler runs again on every poll tick, and
      // socket.io stacks duplicate listeners for the same event name.
      socketService.off('cityparcel:status:update');
      socketService.off('cityparcel:decision-needed');

      // The only two events the backend addresses to `customer:<id>` for a
      // city parcel. Names verified against app/services/cityParcelWorkflow*
      // and cityParcelReturnService — the previously-used
      // `city-parcel:status-update` and `cityparcel:claimed` do not exist,
      // and `cityparcel:cancelled` is emitted to the rider, not the customer.
      socketService.on('cityparcel:status:update', (data) {
        add(TrackingStatusUpdatedFromSocket(data));
      });
      socketService.on('cityparcel:decision-needed', (data) {
        add(TrackingStatusUpdatedFromSocket(data));
      });
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: "Couldn't load tracking details",
      ));
    }
  }

  Future<void> _onRequestOtpRequested(
    TrackingRequestOtpRequested event,
    Emitter<TrackingState> emit,
  ) async {
    emit(state.copyWith(isOtpLoading: true));
    try {
      final code = await trackingRepository.requestHandoverCode(event.parcelId);
      emit(state.copyWith(
        isOtpLoading: false,
        otpCode: code,
        cooldownSeconds: 15,
      ));
    } catch (e) {
      emit(state.copyWith(
        isOtpLoading: false,
        errorMessage: "Couldn't send handover code",
      ));
    }
  }

  Future<void> _onCancelRequested(
    TrackingCancelRequested event,
    Emitter<TrackingState> emit,
  ) async {
    emit(state.copyWith(isCancelling: true, cancelSuccess: false, errorMessage: null));
    try {
      final updated = await trackingRepository.cancelParcel(event.parcelId, reason: event.reason);
      emit(state.copyWith(
        isCancelling: false,
        cancelSuccess: true,
        parcel: updated,
      ));
    } catch (e) {
      emit(state.copyWith(
        isCancelling: false,
        cancelSuccess: false,
        errorMessage: "Couldn't cancel this booking. Please try again.",
      ));
    }
  }

  void _onStatusUpdatedFromSocket(
    TrackingStatusUpdatedFromSocket event,
    Emitter<TrackingState> emit,
  ) {
    if (state.parcel == null) return;
    final payload = event.payload;
    Map? map;
    if (payload is Map) {
      map = payload['payload'] is Map ? payload['payload'] as Map : payload;
    }

    if (map != null) {
      // Events go to the customer's room for EVERY parcel they own.
      final incomingId = map['cityParcelId']?.toString() ??
          (map['parcel'] is Map ? (map['parcel'] as Map)['_id']?.toString() : null);
      if (incomingId != null &&
          incomingId.isNotEmpty &&
          incomingId != state.parcel!.id) {
        return;
      }

      // `cityparcel:decision-needed` carries {outcome, attemptNo, choices,…}
      // but no status: the parcel is DELIVERY_FAILED awaiting the customer.
      final isDecision = map['choices'] is List || map['outcome'] != null;
      final statusVal = map['status']?.toString() ??
          (isDecision ? 'DELIVERY_FAILED' : null) ??
          (map['event'] == 'cityparcel:cancelled' ? 'CANCELLED' : null);

      if (statusVal != null) {
        // copyWith, not a field-by-field rebuild: the old rebuild silently
        // dropped pickup/drop/rider coordinates, so the map went blank on
        // every live update.
        emit(
          state.copyWith(
            parcel: state.parcel!.copyWith(
              status: ParcelStatus.fromString(statusVal),
              returnStatus: isDecision ? 'PENDING_CUSTOMER' : null,
              deliveryAttempts: (map['attemptNo'] as num?)?.toInt(),
              riderLat: _readCoord(map, lat: true),
              riderLng: _readCoord(map, lat: false),
            ),
          ),
        );
      }
    }
  }

  /// Pulls a rider coordinate out of a status payload, tolerating both the
  /// flat `riderLat`/`riderLng` shape and GeoJSON `[lng, lat]`.
  static double? _readCoord(Map map, {required bool lat}) {
    final flat = map[lat ? 'riderLat' : 'riderLng'];
    if (flat is num) return flat.toDouble();
    final loc = map['riderLocation'] ?? map['location'];
    if (loc is Map && loc['coordinates'] is List) {
      final coords = loc['coordinates'] as List;
      if (coords.length >= 2) {
        final value = lat ? coords[1] : coords[0];
        if (value is num) return value.toDouble();
      }
    }
    return null;
  }
}
