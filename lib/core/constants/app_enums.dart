import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

enum UserRole {
  customer,
  seller,
  delivery,
  admin;

  String get value => name;

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'seller':
        return UserRole.seller;
      case 'delivery':
        return UserRole.delivery;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.customer;
    }
  }
}

enum ParcelStatus {
  requested('REQUESTED', 'Awaiting Pickup', StatusTone.idle),
  searching('SEARCHING', 'Finding Rider', StatusTone.warn),
  accepted('ACCEPTED', 'Rider Assigned', StatusTone.transit),
  riderAssigned('RIDER_ASSIGNED', 'On The Way', StatusTone.transit),
  pickupReached('PICKUP_REACHED', 'At Pickup', StatusTone.transit),
  pickedUp('PICKED_UP', 'In Transit', StatusTone.transit),
  // Optional hold between pickup and drop. Present in the backend's
  // CITY_PARCEL_STATUS enum; without it fromString() fell back to REQUESTED
  // and a parcel in custody displayed as "Awaiting Pickup".
  atWaypoint('AT_WAYPOINT', 'In Transit', StatusTone.transit),
  outForDelivery('OUT_FOR_DELIVERY', 'In Transit', StatusTone.transit),
  dropReached('DROP_REACHED', 'At Drop', StatusTone.transit),
  deliveryFailed('DELIVERY_FAILED', 'Needs You', StatusTone.fail),
  returnInTransit('RETURN_IN_TRANSIT', 'Coming Back', StatusTone.warn),
  delivered('DELIVERED', 'Delivered', StatusTone.done),
  returned('RETURNED', 'Returned', StatusTone.idle),
  cancelled('CANCELLED', 'Cancelled', StatusTone.idle);

  final String code;
  final String label;
  final StatusTone tone;

  const ParcelStatus(this.code, this.label, this.tone);

  static ParcelStatus fromString(String? val) {
    if (val == null) return ParcelStatus.requested;
    for (final s in ParcelStatus.values) {
      if (s.code.toUpperCase() == val.toUpperCase()) return s;
    }
    return ParcelStatus.requested;
  }

  bool get isLive =>
      this != ParcelStatus.delivered &&
      this != ParcelStatus.returned &&
      this != ParcelStatus.cancelled;

  bool get isMoving =>
      this == ParcelStatus.pickedUp ||
      this == ParcelStatus.atWaypoint ||
      this == ParcelStatus.outForDelivery ||
      this == ParcelStatus.dropReached;

  /// Rider physically holds the parcel — mirrors the backend's
  /// CITY_PARCEL_IN_CUSTODY_STATUSES. Cancellation is refused (409) here.
  bool get isInRiderCustody =>
      this == ParcelStatus.pickedUp ||
      this == ParcelStatus.atWaypoint ||
      this == ParcelStatus.outForDelivery ||
      this == ParcelStatus.dropReached ||
      this == ParcelStatus.deliveryFailed ||
      this == ParcelStatus.returnInTransit;
}

extension ParcelStatusLocalization on ParcelStatus {
  String getLocalizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return label;
    switch (this) {
      case ParcelStatus.requested:
        return l10n.statusRequested;
      case ParcelStatus.searching:
        return l10n.statusSearching;
      case ParcelStatus.accepted:
        return l10n.statusAccepted;
      case ParcelStatus.riderAssigned:
        return l10n.statusRiderAssigned;
      case ParcelStatus.pickupReached:
        return l10n.statusPickupReached;
      case ParcelStatus.pickedUp:
      case ParcelStatus.atWaypoint:
        return l10n.statusPickedUp;
      case ParcelStatus.outForDelivery:
        return l10n.statusOutForDelivery;
      case ParcelStatus.dropReached:
        return l10n.statusDropReached;
      case ParcelStatus.delivered:
        return l10n.statusDelivered;
      case ParcelStatus.deliveryFailed:
        return l10n.statusDeliveryFailed;
      case ParcelStatus.returnInTransit:
        return l10n.statusReturnInTransit;
      case ParcelStatus.returned:
        return l10n.statusReturned;
      case ParcelStatus.cancelled:
        return l10n.statusCancelled;
    }
  }
}

enum StatusTone {
  transit,
  done,
  warn,
  fail,
  idle;
}

