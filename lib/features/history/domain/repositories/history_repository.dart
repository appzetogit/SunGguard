import '../entities/waybill_item_entity.dart';

abstract class HistoryRepository {
  Future<List<WaybillItemEntity>> getWaybillHistory();
}
