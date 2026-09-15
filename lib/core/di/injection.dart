import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/booking/data/datasources/booking_datasource.dart';
import '../../features/booking/data/repositories/booking_repository_impl.dart';
import '../../features/booking/domain/repositories/booking_repository.dart';
import '../../features/booking/presentation/bloc/booking_bloc.dart';
import '../../features/history/data/datasources/history_datasource.dart';
import '../../features/history/data/repositories/history_repository_impl.dart';
import '../../features/history/domain/repositories/history_repository.dart';
import '../../features/history/presentation/bloc/history_bloc.dart';
import '../../features/parcel_home/data/datasources/parcel_home_datasource.dart';
import '../../features/parcel_home/data/repositories/parcel_home_repository_impl.dart';
import '../../features/parcel_home/domain/repositories/parcel_home_repository.dart';
import '../../features/parcel_home/presentation/bloc/parcel_home_bloc.dart';
import '../../features/profile/data/datasources/profile_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/tracking/data/datasources/tracking_datasource.dart';
import '../../features/tracking/data/repositories/tracking_repository_impl.dart';
import '../../features/tracking/domain/repositories/tracking_repository.dart';
import '../../features/tracking/presentation/bloc/tracking_bloc.dart';
import '../network/api_client.dart';
import '../services/socket_service.dart';
import '../storage/local_storage_service.dart';
import '../storage/secure_storage_service.dart';
import '../localization/app_locale_controller.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // 1. Storage Services
  final localStorage = await LocalStorageService.init();
  sl.registerSingleton<LocalStorageService>(localStorage);

  final secureStorage = SecureStorageService();
  sl.registerSingleton<SecureStorageService>(secureStorage);

  final localeController = AppLocaleController(localStorage);
  sl.registerSingleton<AppLocaleController>(localeController);

  // 2. Network Client & Sockets
  final dio = Dio();
  sl.registerSingleton<Dio>(dio);
  final apiClient = ApiClient(dio: dio, secureStorage: secureStorage);
  // Pages that call ApiClient.createDefault() resolve to this same instance,
  // so their requests go through the interceptor chain too.
  ApiClient.shared = apiClient;
  sl.registerSingleton<ApiClient>(apiClient);
  sl.registerLazySingleton<SocketService>(
    () => SocketService(sl<SecureStorageService>()),
  );

  // 3. Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<ParcelHomeDataSource>(
    () => ParcelHomeDataSourceImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<BookingDataSource>(
    () => BookingDataSourceImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<TrackingDataSource>(
    () => TrackingDataSourceImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<HistoryDataSource>(
    () => HistoryDataSourceImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<ProfileDataSource>(
    () => ProfileDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  // 4. Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      secureStorage: sl<SecureStorageService>(),
      localStorage: sl<LocalStorageService>(),
    ),
  );
  sl.registerLazySingleton<ParcelHomeRepository>(
    () => ParcelHomeRepositoryImpl(dataSource: sl<ParcelHomeDataSource>()),
  );
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(dataSource: sl<BookingDataSource>()),
  );
  sl.registerLazySingleton<TrackingRepository>(
    () => TrackingRepositoryImpl(dataSource: sl<TrackingDataSource>()),
  );
  sl.registerLazySingleton<HistoryRepository>(
    () => HistoryRepositoryImpl(dataSource: sl<HistoryDataSource>()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(dataSource: sl<ProfileDataSource>()),
  );

  // 5. BLoCs
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      authRepository: sl<AuthRepository>(),
      socketService: sl<SocketService>(),
    ),
  );
  sl.registerFactory<ParcelHomeBloc>(
    () => ParcelHomeBloc(parcelHomeRepository: sl<ParcelHomeRepository>()),
  );
  sl.registerFactory<BookingBloc>(
    () => BookingBloc(bookingRepository: sl<BookingRepository>()),
  );
  sl.registerFactory<TrackingBloc>(
    () => TrackingBloc(
      trackingRepository: sl<TrackingRepository>(),
      socketService: sl<SocketService>(),
    ),
  );
  sl.registerFactory<HistoryBloc>(
    () => HistoryBloc(historyRepository: sl<HistoryRepository>()),
  );
  sl.registerFactory<ProfileBloc>(
    () => ProfileBloc(profileRepository: sl<ProfileRepository>()),
  );
}
