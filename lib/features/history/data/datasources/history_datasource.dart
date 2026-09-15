import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/waybill_item_model.dart';

abstract class HistoryDataSource {
  Future<List<WaybillItemModel>> getWaybillHistory();
}

class HistoryDataSourceImpl implements HistoryDataSource {
  final ApiClient apiClient;

  HistoryDataSourceImpl({required this.apiClient});

  @override
  Future<List<WaybillItemModel>> getWaybillHistory() async {
    final results = await Future.wait([
      _fetchCityParcelHistory(),
      _fetchOutstationParcelHistory(),
    ]);

    final combined = [...results[0], ...results[1]];
    combined.sort((a, b) {
      final aDt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDt.compareTo(aDt);
    });
    return combined;
  }

  Future<List<WaybillItemModel>> _fetchCityParcelHistory() async {
    try {
      final res = await apiClient.get(ApiEndpoints.cityParcelHistory);
      final List<dynamic> list = _extractList(res);
      return list
          .map((e) => WaybillItemModel.fromJson(e as Map<String, dynamic>, kind: 'local'))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<WaybillItemModel>> _fetchOutstationParcelHistory() async {
    try {
      final res = await apiClient.get(ApiEndpoints.outstationParcelHistory);
      final List<dynamic> list = _extractList(res);
      return list
          .map((e) => WaybillItemModel.fromJson(e as Map<String, dynamic>, kind: 'outstation'))
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<dynamic> _extractList(dynamic res) {
    if (res is List) {
      return res;
    } else if (res is Map && res['parcels'] is List) {
      return res['parcels'];
    } else if (res is Map && res['results'] is List) {
      return res['results'];
    } else if (res is Map && res['result'] is Map && res['result']['parcels'] is List) {
      return res['result']['parcels'];
    } else if (res is Map && res['result'] is List) {
      return res['result'];
    }
    return [];
  }
}
