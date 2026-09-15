/// Answer from `GET /city-parcel/zone-check?lat&lng`.
///
/// The backend added this so a customer is told "we don't cover this" while
/// they are still looking at the map, instead of three steps later on the
/// payment screen with no idea which address to fix.
class ZoneCheckModel {
  /// False when no delivery zones are drawn at all — nothing is out of bounds.
  final bool gated;
  final bool covered;
  final String? zoneName;
  final String? zoneCity;

  const ZoneCheckModel({
    required this.gated,
    required this.covered,
    this.zoneName,
    this.zoneCity,
  });

  /// Only a gated deployment can put a pin out of bounds.
  bool get isOutOfServiceArea => gated && !covered;

  static ZoneCheckModel fromJson(dynamic res) {
    final data = (res is Map) ? res : const {};
    final zone = data['zone'];
    return ZoneCheckModel(
      gated: data['gated'] == true,
      // Absent means the check could not form an opinion; do not block.
      covered: data['covered'] != false,
      zoneName: (zone is Map) ? zone['name']?.toString() : null,
      zoneCity: (zone is Map) ? zone['city']?.toString() : null,
    );
  }
}
