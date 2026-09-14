import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_enums.dart';

class RiderInfoEntity extends Equatable {
  final String name;
  final String phone;
  final String? vehicleNumber;
  final String? vehicleType;

  const RiderInfoEntity({
    required this.name,
    required this.phone,
    this.vehicleNumber,
    this.vehicleType,
  });

  @override
  List<Object?> get props => [name, phone, vehicleNumber, vehicleType];
}

class TrackingTimelineEventEntity extends Equatable {
  final String status;
  final String? at;
  final String? note;
  final String? actor;

  const TrackingTimelineEventEntity({
    required this.status,
    this.at,
    this.note,
    this.actor,
  });

  @override
  List<Object?> get props => [status, at, note, actor];
}

class ParcelDetailEntity extends Equatable {
  final String id;
  final String referenceId;
  final ParcelStatus status;
  final String pickupAddress;
  final String dropAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;
  final double? riderLat;
  final double? riderLng;
  final String senderName;
  final String senderPhone;
  final String receiverName;
  final String receiverPhone;
  final String packageType;
  final double weightKg;
  final double amount;
  final RiderInfoEntity? rider;
  final String? handoverCode;
  final String? createdAt;
  final List<TrackingTimelineEventEntity> timeline;

  /// Payment + return metadata the backend has always sent on
  /// `GET /city-parcel/track/:id` and the app used to discard.
  final String paymentMethod;
  final String paymentStatus;
  final String returnStatus;
  final String customerChoice;
  final int deliveryAttempts;
  final String? deliveryDeadline;
  final double codAmount;
  final String? razorpayOrderId;

  const ParcelDetailEntity({
    required this.id,
    required this.referenceId,
    required this.status,
    required this.pickupAddress,
    required this.dropAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.riderLat,
    this.riderLng,
    required this.senderName,
    required this.senderPhone,
    required this.receiverName,
    required this.receiverPhone,
    required this.packageType,
    required this.weightKg,
    required this.amount,
    this.rider,
    this.handoverCode,
    this.createdAt,
    this.timeline = const [],
    this.paymentMethod = '',
    this.paymentStatus = '',
    this.returnStatus = '',
    this.customerChoice = '',
    this.deliveryAttempts = 0,
    this.deliveryDeadline,
    this.codAmount = 0.0,
    this.razorpayOrderId,
  });

  /// Returns a copy with only the named fields replaced.
  ///
  /// Exists so a socket status push can update the status without rebuilding
  /// the entity field by field — the hand-rolled rebuild this replaces dropped
  /// every coordinate, which blanked the tracking map on each live update.
  ParcelDetailEntity copyWith({
    ParcelStatus? status,
    RiderInfoEntity? rider,
    String? handoverCode,
    List<TrackingTimelineEventEntity>? timeline,
    double? riderLat,
    double? riderLng,
    String? paymentStatus,
    String? returnStatus,
    String? customerChoice,
    int? deliveryAttempts,
  }) {
    return ParcelDetailEntity(
      id: id,
      referenceId: referenceId,
      status: status ?? this.status,
      pickupAddress: pickupAddress,
      dropAddress: dropAddress,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropLat: dropLat,
      dropLng: dropLng,
      riderLat: riderLat ?? this.riderLat,
      riderLng: riderLng ?? this.riderLng,
      senderName: senderName,
      senderPhone: senderPhone,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      packageType: packageType,
      weightKg: weightKg,
      amount: amount,
      rider: rider ?? this.rider,
      handoverCode: handoverCode ?? this.handoverCode,
      createdAt: createdAt,
      timeline: timeline ?? this.timeline,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      returnStatus: returnStatus ?? this.returnStatus,
      customerChoice: customerChoice ?? this.customerChoice,
      deliveryAttempts: deliveryAttempts ?? this.deliveryAttempts,
      deliveryDeadline: deliveryDeadline,
      codAmount: codAmount,
      razorpayOrderId: razorpayOrderId,
    );
  }

  /// True while the booking is waiting on an online payment that never
  /// completed. The backend leaves such a parcel at REQUESTED and does not
  /// broadcast it to riders, so the customer has to be offered the gateway
  /// again rather than shown a tracking screen that will never advance.
  bool get awaitingPayment =>
      paymentStatus.toUpperCase() == 'PENDING' &&
      paymentMethod.toUpperCase() != 'COD' &&
      status == ParcelStatus.requested;

  @override
  List<Object?> get props => [
    id,
    referenceId,
    status,
    pickupAddress,
    dropAddress,
    pickupLat,
    pickupLng,
    dropLat,
    dropLng,
    riderLat,
    riderLng,
    senderName,
    senderPhone,
    receiverName,
    receiverPhone,
    packageType,
    weightKg,
    amount,
    rider,
    handoverCode,
    createdAt,
    timeline,
    paymentMethod,
    paymentStatus,
    returnStatus,
    customerChoice,
    deliveryAttempts,
    deliveryDeadline,
    codAmount,
    razorpayOrderId,
  ];
}
