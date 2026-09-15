import '../../domain/entities/parcel_summary_entity.dart';
import '../../domain/repositories/parcel_home_repository.dart';
import '../datasources/parcel_home_datasource.dart';

class ParcelHomeRepositoryImpl implements ParcelHomeRepository {
  final ParcelHomeDataSource dataSource;

  ParcelHomeRepositoryImpl({required this.dataSource});

  @override
  Future<List<ParcelSummaryEntity>> getActiveShipments() {
    return dataSource.getActiveShipments();
  }
}
