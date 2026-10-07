import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_odoo_app/core/errors/exceptions.dart';
import 'package:sales_odoo_app/core/errors/failures.dart';
import 'package:sales_odoo_app/core/network/network_info.dart';
import 'package:sales_odoo_app/features/sales_orders/data/datasources/sales_order_local_datasource.dart';
import 'package:sales_odoo_app/features/sales_orders/data/datasources/sales_order_remote_datasource.dart';
import 'package:sales_odoo_app/features/sales_orders/data/models/sales_order_model.dart';
import 'package:sales_odoo_app/features/sales_orders/data/repositories/sales_order_repository_impl.dart';

class MockSalesOrderRemoteDataSource extends Mock
    implements SalesOrderRemoteDataSource {}

class MockSalesOrderLocalDataSource extends Mock
    implements SalesOrderLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late SalesOrderRepositoryImpl repository;
  late MockSalesOrderRemoteDataSource mockRemote;
  late MockSalesOrderLocalDataSource mockLocal;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemote = MockSalesOrderRemoteDataSource();
    mockLocal = MockSalesOrderLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    when(
      () => mockLocal.updateCachedSalesOrderState(any(), any()),
    ).thenAnswer((_) async {});
    repository = SalesOrderRepositoryImpl(
      remoteDataSource: mockRemote,
      localDataSource: mockLocal,
      networkInfo: mockNetworkInfo,
    );
  });

  const tOrder = SalesOrderModel(
    id: 1,
    name: 'SO01',
    customerName: 'Cust',
    dateOrder: 'date',
    state: 'draft',
    amountTotal: 100,
    orderLineIds: [],
  );

  test('delegates getSalesOrders to remote when online', () async {
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    when(() => mockRemote.getSalesOrders()).thenAnswer((_) async => [tOrder]);
    when(() => mockLocal.cacheSalesOrders(any())).thenAnswer((_) async {});

    final result = await repository.getSalesOrders();
    expect(result.$2, [tOrder]);
  });

  test('propagates error from remote', () async {
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    when(
      () => mockRemote.getSalesOrders(),
    ).thenThrow(const ServerException('Error'));

    final result = await repository.getSalesOrders();
    expect(result.$1, isA<ServerFailure>());
  });

  test('delegates confirmation behavior online', () async {
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    when(() => mockRemote.confirmSalesOrder(1)).thenAnswer((_) async {});
    when(() => mockLocal.removePendingConfirmation(1)).thenAnswer((_) async {});

    final result = await repository.confirmSalesOrder(1);
    expect(result, isNull);
    verify(() => mockRemote.confirmSalesOrder(1)).called(1);
  });

  test('offline confirm saves pending confirmation locally', () async {
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
    when(() => mockLocal.savePendingConfirmation(1)).thenAnswer((_) async {});

    final result = await repository.confirmSalesOrder(1);
    expect(result, isNull);
    verify(() => mockLocal.savePendingConfirmation(1)).called(1);
  });

  test(
    'syncPendingConfirmations processes pending order and removes it on success',
    () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => mockLocal.getPendingConfirmations(),
      ).thenAnswer((_) async => [1]);
      when(() => mockRemote.confirmSalesOrder(1)).thenAnswer((_) async {});
      when(
        () => mockLocal.removePendingConfirmation(1),
      ).thenAnswer((_) async {});

      await repository.syncPendingConfirmations();

      verify(() => mockRemote.confirmSalesOrder(1)).called(1);
      verify(() => mockLocal.removePendingConfirmation(1)).called(1);
    },
  );

  test('failed sync keeps pending confirmation', () async {
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    when(
      () => mockLocal.getPendingConfirmations(),
    ).thenAnswer((_) async => [1]);
    when(() => mockRemote.confirmSalesOrder(1)).thenThrow(Exception('Fail'));

    await repository.syncPendingConfirmations();

    verify(() => mockRemote.confirmSalesOrder(1)).called(1);
    verifyNever(() => mockLocal.removePendingConfirmation(1));
  });
}
