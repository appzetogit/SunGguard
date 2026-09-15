import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<void> sendLoginOtp(String phone);
  Future<void> sendSignupOtp(String name, String phone);
  Future<UserModel> verifyLoginOtp(String phone, String otp);
  Future<UserModel> verifySignupOtp(String name, String phone, String otp);
  Future<UserModel> getProfile();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<void> sendLoginOtp(String phone) async {
    await apiClient.post(
      ApiEndpoints.customerSendLoginOtp,
      data: {'phone': phone},
    );
  }

  @override
  Future<void> sendSignupOtp(String name, String phone) async {
    await apiClient.post(
      ApiEndpoints.customerSendSignupOtp,
      data: {'name': name, 'phone': phone},
    );
  }

  @override
  Future<UserModel> verifyLoginOtp(String phone, String otp) async {
    final res = await apiClient.post(
      ApiEndpoints.customerVerifyOtp,
      data: {'phone': phone, 'otp': otp},
    );
    final data = res as Map<String, dynamic>;
    final token = data['token'] as String?;
    final userData = (data['customer'] ?? data['user'] ?? data) as Map<String, dynamic>;
    return UserModel.fromJson(userData, token: token);
  }

  @override
  Future<UserModel> verifySignupOtp(String name, String phone, String otp) async {
    final res = await apiClient.post(
      ApiEndpoints.customerVerifyOtp,
      data: {'name': name, 'phone': phone, 'otp': otp},
    );
    final data = res as Map<String, dynamic>;
    final token = data['token'] as String?;
    final userData = (data['customer'] ?? data['user'] ?? data) as Map<String, dynamic>;
    return UserModel.fromJson(userData, token: token);
  }

  @override
  Future<UserModel> getProfile() async {
    final res = await apiClient.get(ApiEndpoints.customerProfile);
    final data = (res is Map<String, dynamic>)
        ? (res['result'] ?? res['data'] ?? res['customer'] ?? res['user'] ?? res) as Map<String, dynamic>
        : <String, dynamic>{};
    return UserModel.fromJson(data);
  }
}
