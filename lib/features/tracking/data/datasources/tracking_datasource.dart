import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../models/parcel_detail_model.dart';

abstract class TrackingDataSource {
  Future<ParcelDetailModel> getParcelDetails(String parcelId);
  Future<String> requestHandoverCode(String parcelId);
  Future<ParcelDetailModel> cancelParcel(String parcelId, {String? reason});
}

class TrackingDataSourceImpl implements TrackingDataSource {
  final ApiClient apiClient;

  TrackingDataSourceImpl({required this.apiClient});

  @override
  Future<ParcelDetailModel> getParcelDetails(String parcelId) async {
    final res = await apiClient.get(ApiEndpoints.cityParcelDetail(parcelId));
    if (res is Map<String, dynamic>) {
      return ParcelDetailModel.fromJson(res);
    }
    throw const ApiException(message: 'Invalid tracking details response');
  }

  @override
  Future<String> requestHandoverCode(String parcelId) async {
    final res = await apiClient.post(ApiEndpoints.cityParcelRequestCode(parcelId));
    final data = res is Map ? (res['result'] ?? res['data'] ?? res) : {};
    if (data is Map) {
      return data['devCode']?.toString() ??
          data['code']?.toString() ??
          data['otp']?.toString() ??
          '';
    }
    return '';
  }

  @override
  Future<ParcelDetailModel> cancelParcel(String parcelId, {String? reason}) async {
    final res = await apiClient.post(
      ApiEndpoints.cityParcelCancel(parcelId),
      data: {'reason': reason ?? ''},
    );
    // The cancel response carries an unpopulated parcel and no timeline, so
    // re-read the tracking view (as the web app does) to keep rider + events.
    try {
      return await getParcelDetails(parcelId);
    } catch (_) {
      if (res is Map<String, dynamic>) return ParcelDetailModel.fromJson(res);
      throw const ApiException(message: 'Invalid cancel response from server');
    }
  }
}
