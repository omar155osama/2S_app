import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_odoo_app/core/network/offline_sync_manager.dart';
import 'package:sales_odoo_app/core/errors/failures.dart';
import 'package:sales_odoo_app/features/sales_orders/data/models/sales_order_line_model.dart';
import 'package:sales_odoo_app/features/sales_orders/data/models/sales_order_model.dart';
import 'package:sales_odoo_app/features/sales_orders/data/repositories/sales_order_repository_impl.dart';
import 'package:sales_odoo_app/features/sales_orders/presentation/cubit/sales_orders_cubit.dart';
import 'package:sales_odoo_app/features/sales_orders/presentation/cubit/sales_orders_state.dart';

class MockSalesOrderRepository extends Mock implements SalesOrderRepository {}

class MockOfflineSyncManager extends Mock implements OfflineSyncManager {}

void main() {
  late SalesOrdersCubit cubit;
  late MockSalesOrderRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(<int>[]);
  });

  setUp(() {
    mockRepository = MockSalesOrderRepository();
    when(
      () => mockRepository.hasPendingConfirmation(any()),
    ).thenAnswer((_) async => false);
    cubit = SalesOrdersCubit(repository: mockRepository);
  });

  const tOrder = SalesOrderModel(
    id: 1,
    name: 'SO',
    customerName: 'Cust',
    dateOrder: 'date',
    state: 'draft',
    amountTotal: 100,
    orderLineIds: [],
  );

  blocTest<SalesOrdersCubit, SalesOrdersState>(
    'emits success on fetch',
    build: () {
      when(
        () => mockRepository.getSalesOrders(),
      ).thenAnswer((_) async => (null, [tOrder]));
      return cubit;
    },
    act: (cubit) => cubit.fetchSalesOrders(),
    expect: () => [isA<SalesOrdersLoading>(), isA<SalesOrdersSuccess>()],
  );

  blocTest<SalesOrdersCubit, SalesOrdersState>(
    'emits empty on empty list',
    build: () {
      when(
        () => mockRepository.getSalesOrders(),
      ).thenAnswer((_) async => (null, <SalesOrderModel>[]));
      return cubit;
    },
    act: (cubit) => cubit.fetchSalesOrders(),
    expect: () => [isA<SalesOrdersLoading>(), isA<SalesOrdersEmpty>()],
  );

  blocTest<SalesOrdersCubit, SalesOrdersState>(
    'emits error on failure',
    build: () {
      when(
        () => mockRepository.getSalesOrders(),
      ).thenAnswer((_) async => (const ServerFailure('E'), null));
      return cubit;
    },
    act: (cubit) => cubit.fetchSalesOrders(),
    expect: () => [isA<SalesOrdersLoading>(), isA<SalesOrdersError>()],
  );

  blocTest<SalesOrdersCubit, SalesOrdersState>(
    'emits details success',
    build: () {
      when(
        () => mockRepository.getSalesOrder(1),
      ).thenAnswer((_) async => (null, tOrder));
      when(
        () => mockRepository.getSalesOrderLines(any()),
      ).thenAnswer((_) async => (null, <SalesOrderLineModel>[]));
      return cubit;
    },
    act: (cubit) => cubit.fetchSalesOrderDetails(1),
    expect: () => [
      isA<SalesOrderDetailLoading>(),
      isA<SalesOrderDetailSuccess>(),
    ],
  );

  blocTest<SalesOrdersCubit, SalesOrdersState>(
    'confirmSalesOrder emits SalesOrderConfirming and refreshes order on success',
    build: () {
      when(
        () => mockRepository.confirmSalesOrder(1),
      ).thenAnswer((_) async => null);
      when(
        () => mockRepository.getSalesOrder(1),
      ).thenAnswer((_) async => (null, tOrder));
      when(
        () => mockRepository.getSalesOrderLines(any()),
      ).thenAnswer((_) async => (null, <SalesOrderLineModel>[]));
      return cubit;
    },
    seed: () => const SalesOrderDetailSuccess(tOrder, []),
    act: (cubit) => cubit.confirmSalesOrder(1),
    expect: () => [
      isA<SalesOrderConfirming>(),
      isA<SalesOrderDetailLoading>(),
      isA<SalesOrderDetailSuccess>(),
    ],
    verify: (_) {
      verify(() => mockRepository.confirmSalesOrder(1)).called(1);
      verify(() => mockRepository.getSalesOrder(1)).called(1);
    },
  );

  blocTest<SalesOrdersCubit, SalesOrdersState>(
    'confirmSalesOrder emits error on failure',
    build: () {
      when(
        () => mockRepository.confirmSalesOrder(1),
      ).thenAnswer((_) async => const ServerFailure('Permission Denied'));
      return cubit;
    },
    seed: () => const SalesOrderDetailSuccess(tOrder, []),
    act: (cubit) => cubit.confirmSalesOrder(1),
    expect: () => [
      isA<SalesOrderConfirming>(),
      isA<SalesOrderDetailError>(),
      isA<SalesOrderDetailSuccess>(),
    ],
    verify: (_) {
      verify(() => mockRepository.confirmSalesOrder(1)).called(1);
    },
  );

  test('refreshes order details when sync completes', () async {
    final mockSyncManager = MockOfflineSyncManager();
    final controller = StreamController<void>.broadcast();
    when(
      () => mockSyncManager.onSyncCompleted,
    ).thenAnswer((_) => controller.stream);
    when(
      () => mockRepository.getSalesOrder(1),
    ).thenAnswer((_) async => (null, tOrder));
    when(
      () => mockRepository.getSalesOrderLines(any()),
    ).thenAnswer((_) async => (null, <SalesOrderLineModel>[]));

    final testCubit = SalesOrdersCubit(
      repository: mockRepository,
      offlineSyncManager: mockSyncManager,
    );
    testCubit.emit(const SalesOrderDetailSuccess(tOrder, []));

    controller.add(null);
    await Future.delayed(Duration.zero);

    verify(() => mockRepository.getSalesOrder(1)).called(1);
    await testCubit.close();
    await controller.close();
  });
}
