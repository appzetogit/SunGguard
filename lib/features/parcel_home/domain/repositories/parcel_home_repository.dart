import '../entities/parcel_summary_entity.dart';

abstract class ParcelHomeRepository {
  Future<List<ParcelSummaryEntity>> getActiveShipments();
}
