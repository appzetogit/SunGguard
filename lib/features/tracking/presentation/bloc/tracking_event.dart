import 'package:equatable/equatable.dart';

abstract class TrackingEvent extends Equatable {
  const TrackingEvent();

  @override
  List<Object?> get props => [];
}

class TrackingLoadRequested extends TrackingEvent {
  final String parcelId;

  const TrackingLoadRequested(this.parcelId);

  @override
  List<Object?> get props => [parcelId];
}

class TrackingRequestOtpRequested extends TrackingEvent {
  final String parcelId;

  const TrackingRequestOtpRequested(this.parcelId);

  @override
  List<Object?> get props => [parcelId];
}

class TrackingStatusUpdatedFromSocket extends TrackingEvent {
  final dynamic payload;

  const TrackingStatusUpdatedFromSocket(this.payload);

  @override
  List<Object?> get props => [payload];
}

class TrackingCancelRequested extends TrackingEvent {
  final String parcelId;
  final String? reason;

  const TrackingCancelRequested(this.parcelId, {this.reason});

  @override
  List<Object?> get props => [parcelId, reason];
}
