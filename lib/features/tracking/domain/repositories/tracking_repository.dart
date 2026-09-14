import '../entities/parcel_detail_entity.dart';

abstract class TrackingRepository {
  Future<ParcelDetailEntity> getParcelDetails(String parcelId);
  Future<String> requestHandoverCode(String parcelId);
  Future<ParcelDetailEntity> cancelParcel(String parcelId, {String? reason});
}
