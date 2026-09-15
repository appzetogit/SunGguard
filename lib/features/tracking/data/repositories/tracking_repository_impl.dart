import '../../domain/entities/parcel_detail_entity.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/tracking_datasource.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  final TrackingDataSource dataSource;

  TrackingRepositoryImpl({required this.dataSource});

  @override
  Future<ParcelDetailEntity> getParcelDetails(String parcelId) {
    return dataSource.getParcelDetails(parcelId);
  }

  @override
  Future<String> requestHandoverCode(String parcelId) {
    return dataSource.requestHandoverCode(parcelId);
  }

  @override
  Future<ParcelDetailEntity> cancelParcel(String parcelId, {String? reason}) {
    return dataSource.cancelParcel(parcelId, reason: reason);
  }
}
