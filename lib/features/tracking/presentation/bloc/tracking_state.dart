import 'package:equatable/equatable.dart';
import '../../domain/entities/parcel_detail_entity.dart';

class TrackingState extends Equatable {
  final bool isLoading;
  final bool isOtpLoading;
  final bool isCancelling;
  final bool cancelSuccess;
  final ParcelDetailEntity? parcel;
  final String? otpCode;
  final int cooldownSeconds;
  final String? errorMessage;

  const TrackingState({
    this.isLoading = false,
    this.isOtpLoading = false,
    this.isCancelling = false,
    this.cancelSuccess = false,
    this.parcel,
    this.otpCode,
    this.cooldownSeconds = 0,
    this.errorMessage,
  });

  TrackingState copyWith({
    bool? isLoading,
    bool? isOtpLoading,
    bool? isCancelling,
    bool? cancelSuccess,
    ParcelDetailEntity? parcel,
    String? otpCode,
    int? cooldownSeconds,
    String? errorMessage,
  }) {
    return TrackingState(
      isLoading: isLoading ?? this.isLoading,
      isOtpLoading: isOtpLoading ?? this.isOtpLoading,
      isCancelling: isCancelling ?? this.isCancelling,
      cancelSuccess: cancelSuccess ?? this.cancelSuccess,
      parcel: parcel ?? this.parcel,
      otpCode: otpCode ?? this.otpCode,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isOtpLoading,
        isCancelling,
        cancelSuccess,
        parcel,
        otpCode,
        cooldownSeconds,
        errorMessage,
      ];
}
