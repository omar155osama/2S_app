import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_odoo_app/features/sales_orders/data/models/sales_order_model.dart';
import 'package:sales_odoo_app/features/sales_orders/presentation/cubit/sales_orders_cubit.dart';
import 'package:sales_odoo_app/features/sales_orders/presentation/cubit/sales_orders_state.dart';
import 'package:sales_odoo_app/features/sales_orders/presentation/pages/sales_order_details_page.dart';
import 'package:bloc_test/bloc_test.dart';

class MockSalesOrdersCubit extends MockCubit<SalesOrdersState>
    implements SalesOrdersCubit {}

void main() {
  late MockSalesOrdersCubit mockCubit;

  setUp(() {
    mockCubit = MockSalesOrdersCubit();
    GetIt.I.registerFactory<SalesOrdersCubit>(() => mockCubit);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  Widget buildTestWidget() {
    return const MaterialApp(home: SalesOrderDetailsPage(orderId: 1));
  }

  const tOrderDraft = SalesOrderModel(
    id: 1,
    name: 'SO01',
    customerName: 'Cust',
    dateOrder: 'date',
    state: 'draft',
    amountTotal: 100,
    orderLineIds: [],
  );

  const tOrderDone = SalesOrderModel(
    id: 1,
    name: 'SO01',
    customerName: 'Cust',
    dateOrder: 'date',
    state: 'done',
    amountTotal: 100,
    orderLineIds: [],
  );

  testWidgets('renders success state and confirm button if draft', (
    tester,
  ) async {
    when(
      () => mockCubit.state,
    ).thenReturn(const SalesOrderDetailSuccess(tOrderDraft, []));
    when(() => mockCubit.fetchSalesOrderDetails(1)).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('SO01'), findsOneWidget);
    expect(find.text('Confirm Order'), findsOneWidget);
  });

  testWidgets('hides confirm button if not draft', (tester) async {
    when(
      () => mockCubit.state,
    ).thenReturn(const SalesOrderDetailSuccess(tOrderDone, []));
    when(() => mockCubit.fetchSalesOrderDetails(1)).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Confirm Order'), findsNothing);
  });
}
