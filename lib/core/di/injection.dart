import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sales_odoo_app/core/network/network_info.dart';
import 'package:sales_odoo_app/core/network/offline_sync_manager.dart';
import 'package:sales_odoo_app/core/network/odoo_config.dart';
import 'package:sales_odoo_app/core/network/odoo_http_client.dart';
import 'package:sales_odoo_app/core/network/session_manager.dart';
import 'package:sales_odoo_app/features/auth/data/datasources/odoo_auth_datasource.dart';
import 'package:sales_odoo_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sales_odoo_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_odoo_app/features/customers/data/datasources/customer_local_datasource.dart';
import 'package:sales_odoo_app/features/customers/data/datasources/customer_remote_datasource.dart';
import 'package:sales_odoo_app/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:sales_odoo_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:sales_odoo_app/features/sales_orders/data/datasources/sales_order_local_datasource.dart';
import 'package:sales_odoo_app/features/sales_orders/data/datasources/sales_order_remote_datasource.dart';
import 'package:sales_odoo_app/features/sales_orders/data/repositories/sales_order_repository_impl.dart';
import 'package:sales_odoo_app/features/sales_orders/presentation/cubit/sales_orders_cubit.dart';
import 'package:sales_odoo_app/core/theme/theme_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> initDI({
  SharedPreferences? sharedPreferences,
  Connectivity? connectivity,
  String? testOdooUrl,
  String? testOdooDatabase,
}) async {
  final prefs = sharedPreferences ?? await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<Connectivity>(() => connectivity ?? Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  final odooUrl =
      testOdooUrl ??
      const String.fromEnvironment(
        'ODOO_URL',
        defaultValue: 'https://2s-test.odoo.com',
      );

  final odooDatabase =
      testOdooDatabase ??
      const String.fromEnvironment('ODOO_DATABASE', defaultValue: '2s-test');

  if (odooUrl.isEmpty) {
    throw Exception(
      'ODOO_URL is missing or empty. Please provide a valid URL.',
    );
  }

  if (odooDatabase.isEmpty) {
    throw Exception(
      'ODOO_DATABASE is missing or empty. Please provide a valid database.',
    );
  }

  // Core
  sl.registerLazySingleton<OdooConfig>(
    () => OdooConfig(baseUrl: odooUrl, database: odooDatabase),
  );
  sl.registerLazySingleton<http.Client>(
    () => OdooHttpClient(http.Client(), sl()),
  );
  sl.registerLazySingleton<SessionManager>(() => SessionManager());

  // Features - Auth
  // Data sources
  sl.registerLazySingleton<OdooAuthDataSource>(
    () => OdooAuthDataSourceImpl(config: sl(), client: sl()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dataSource: sl(), config: sl()),
  );

  // Cubits
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit(prefs: sl()));
  sl.registerFactory(() => AuthCubit(repository: sl(), sessionManager: sl()));

  // Features - Customers
  // Data sources
  sl.registerLazySingleton<CustomerRemoteDataSource>(
    () => CustomerRemoteDataSourceImpl(
      config: sl(),
      client: sl(),
      sessionManager: sl(),
    ),
  );

  sl.registerLazySingleton<CustomerLocalDataSource>(
    () => CustomerLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // Repository
  sl.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Features - Sales Orders
  sl.registerLazySingleton<SalesOrderLocalDataSource>(
    () => SalesOrderLocalDataSourceImpl(sharedPreferences: sl()),
  );

  sl.registerLazySingleton<SalesOrderRemoteDataSource>(
    () => SalesOrderRemoteDataSourceImpl(
      config: sl(),
      sessionManager: sl(),
      client: sl(),
    ),
  );

  sl.registerLazySingleton<SalesOrderRepository>(
    () => SalesOrderRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Offline Sync Manager
  sl.registerLazySingleton<OfflineSyncManager>(
    () => OfflineSyncManager(
      customerRepository: sl(),
      salesOrderRepository: sl(),
      connectivity: sl(),
      networkInfo: sl(),
    )..startListening(),
  );

  // Cubits
  sl.registerFactory(
    () => CustomersCubit(repository: sl(), offlineSyncManager: sl()),
  );
  sl.registerFactory(
    () => SalesOrdersCubit(repository: sl(), offlineSyncManager: sl()),
  );
}
