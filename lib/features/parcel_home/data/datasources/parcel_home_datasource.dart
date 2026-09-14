import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/parcel_summary_model.dart';

abstract class ParcelHomeDataSource {
  Future<List<ParcelSummaryModel>> getActiveShipments();
}

class ParcelHomeDataSourceImpl implements ParcelHomeDataSource {
  final ApiClient apiClient;
  final SecureStorageService storageService;

  ParcelHomeDataSourceImpl({
    required this.apiClient,
    SecureStorageService? storageService,
  }) : storageService = storageService ?? SecureStorageService();

  @override
  Future<List<ParcelSummaryModel>> getActiveShipments() async {
    final token = await storageService.getCustomerToken();
    if (token == null || token.isEmpty) {
      return [];
    }

    final results = await Future.wait([
      _fetchLocalActiveShipments(),
      _fetchOutstationActiveShipments(),
    ]);

    return [...results[0], ...results[1]];
  }

  Future<List<ParcelSummaryModel>> _fetchLocalActiveShipments() async {
    try {
      final res = await apiClient.get(ApiEndpoints.cityParcelHistory);
      final List<dynamic> list = _extractList(res);
      final all = list
          .map((e) => ParcelSummaryModel.fromJson(e as Map<String, dynamic>, kind: 'local'))
          .toList();
      return all.where((p) => p.status.isLive).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ParcelSummaryModel>> _fetchOutstationActiveShipments() async {
    try {
      final res = await apiClient.get(ApiEndpoints.outstationParcelHistory);
      final List<dynamic> list = _extractList(res);
      final all = list
          .map((e) => ParcelSummaryModel.fromJson(e as Map<String, dynamic>, kind: 'outstation'))
          .toList();
      return all.where((p) => p.status.isLive).toList();
    } catch (_) {
      return [];
    }
  }

  List<dynamic> _extractList(dynamic res) {
    if (res is List) return res;
    if (res is Map) {
      if (res['parcels'] is List) return res['parcels'];
      if (res['results'] is List) return res['results'];
      if (res['result'] is List) return res['result'];
      if (res['result'] is Map) {
        if (res['result']['parcels'] is List) return res['result']['parcels'];
        if (res['result']['results'] is List) return res['result']['results'];
      }
    }
    return [];
  }
}
