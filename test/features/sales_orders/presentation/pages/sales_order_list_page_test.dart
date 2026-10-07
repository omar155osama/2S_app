import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_odoo_app/core/network/session_manager.dart';
import 'package:sales_odoo_app/features/sales_orders/data/models/sales_order_model.dart';
import 'package:sales_odoo_app/features/sales_orders/presentation/cubit/sales_orders_cubit.dart';
import 'package:sales_odoo_app/features/sales_orders/presentation/cubit/sales_orders_state.dart';
import 'package:sales_odoo_app/features/sales_orders/presentation/pages/sales_order_list_page.dart';
import 'package:bloc_test/bloc_test.dart';

class MockSalesOrdersCubit extends MockCubit<SalesOrdersState>
    implements SalesOrdersCubit {}

class MockSessionManager extends Mock implements SessionManager {}

void main() {
  late MockSalesOrdersCubit mockCubit;
  late MockSessionManager mockSessionManager;

  setUp(() {
    mockCubit = MockSalesOrdersCubit();
    mockSessionManager = MockSessionManager();
    when(() => mockSessionManager.currentUser).thenReturn(null);
    GetIt.I.registerFactory<SalesOrdersCubit>(() => mockCubit);
    GetIt.I.registerLazySingleton<SessionManager>(() => mockSessionManager);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  Widget buildTestWidget() {
    return const MaterialApp(home: SalesOrderListPage());
  }

  testWidgets('renders loading state', (tester) async {
    when(() => mockCubit.state).thenReturn(SalesOrdersLoading());
    when(() => mockCubit.fetchSalesOrders()).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Recent Orders'), findsWidgets);
  });

  testWidgets('renders success state with list', (tester) async {
    final orders = [
      SalesOrderModel(
        id: 1,
        name: 'SO01',
        customerName: 'Cust',
        dateOrder: DateTime.now().toString(),
        state: 'draft',
        amountTotal: 100,
        orderLineIds: const [],
      ),
    ];
    when(() => mockCubit.state).thenReturn(SalesOrdersSuccess(orders));
    when(() => mockCubit.fetchSalesOrders()).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('SO01'), findsOneWidget);
    expect(find.text('Quotation'), findsOneWidget);
  });
}
