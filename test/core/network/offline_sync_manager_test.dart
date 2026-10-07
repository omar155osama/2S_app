import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_odoo_app/core/network/network_info.dart';
import 'package:sales_odoo_app/core/network/offline_sync_manager.dart';
import 'package:sales_odoo_app/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:sales_odoo_app/features/sales_orders/data/repositories/sales_order_repository_impl.dart';

class MockCustomerRepository extends Mock implements CustomerRepository {}

class MockSalesOrderRepository extends Mock implements SalesOrderRepository {}

class MockConnectivity extends Mock implements Connectivity {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late OfflineSyncManager syncManager;
  late MockCustomerRepository mockCustomerRepo;
  late MockSalesOrderRepository mockSalesOrderRepo;
  late MockConnectivity mockConnectivity;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockCustomerRepo = MockCustomerRepository();
    mockSalesOrderRepo = MockSalesOrderRepository();
    mockConnectivity = MockConnectivity();
    mockNetworkInfo = MockNetworkInfo();

    syncManager = OfflineSyncManager(
      customerRepository: mockCustomerRepo,
      salesOrderRepository: mockSalesOrderRepo,
      connectivity: mockConnectivity,
      networkInfo: mockNetworkInfo,
    );
  });

  tearDown(() {
    syncManager.dispose();
  });

  test(
    'connectivity restoration triggers sync for customer and sales order',
    () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => mockCustomerRepo.syncPendingChanges(),
      ).thenAnswer((_) async {});
      when(
        () => mockSalesOrderRepo.syncPendingConfirmations(),
      ).thenAnswer((_) async {});

      await syncManager.syncAllPendingActions();

      verify(() => mockCustomerRepo.syncPendingChanges()).called(1);
      verify(() => mockSalesOrderRepo.syncPendingConfirmations()).called(1);
    },
  );
}
