import '../../domain/entities/waybill_item_entity.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_datasource.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryDataSource dataSource;

  HistoryRepositoryImpl({required this.dataSource});

  @override
  Future<List<WaybillItemEntity>> getWaybillHistory() {
    return dataSource.getWaybillHistory();
  }
}
