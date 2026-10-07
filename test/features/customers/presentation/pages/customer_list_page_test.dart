import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_odoo_app/core/network/session_manager.dart';
import 'package:sales_odoo_app/features/auth/data/models/auth_session_model.dart';
import 'package:sales_odoo_app/features/customers/data/models/customer_model.dart';
import 'package:sales_odoo_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:sales_odoo_app/features/customers/presentation/cubit/customers_state.dart';
import 'package:sales_odoo_app/features/customers/presentation/pages/customer_list_page.dart';
import 'package:sales_odoo_app/features/home/presentation/pages/main_layout_page.dart';
import 'package:sales_odoo_app/features/sales_orders/presentation/cubit/sales_orders_cubit.dart';
import 'package:sales_odoo_app/features/sales_orders/presentation/cubit/sales_orders_state.dart';
import 'package:sales_odoo_app/core/theme/theme_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MockCustomersCubit extends MockCubit<CustomersState>
    implements CustomersCubit {}

class MockSalesOrdersCubit extends MockCubit<SalesOrdersState>
    implements SalesOrdersCubit {}

class MockThemeCubit extends MockCubit<ThemeMode> implements ThemeCubit {}

class MockSessionManager extends Mock implements SessionManager {}

void main() {
  late MockCustomersCubit mockCubit;
  late MockSalesOrdersCubit mockSalesOrdersCubit;
  late MockThemeCubit mockThemeCubit;
  late MockSessionManager mockSessionManager;

  setUp(() {
    mockCubit = MockCustomersCubit();
    mockSalesOrdersCubit = MockSalesOrdersCubit();
    mockThemeCubit = MockThemeCubit();
    mockSessionManager = MockSessionManager();
    when(() => mockSessionManager.currentUser).thenReturn(null);
    when(
      () => mockSalesOrdersCubit.state,
    ).thenReturn(SalesOrdersSuccess(const []));
    when(
      () => mockSalesOrdersCubit.fetchSalesOrders(),
    ).thenAnswer((_) async {});
    when(() => mockThemeCubit.state).thenReturn(ThemeMode.light);

    GetIt.I.registerFactory<CustomersCubit>(() => mockCubit);
    GetIt.I.registerFactory<SalesOrdersCubit>(() => mockSalesOrdersCubit);
    GetIt.I.registerLazySingleton<SessionManager>(() => mockSessionManager);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  Widget buildTestWidget() {
    return const MaterialApp(home: CustomerListPage());
  }

  Widget buildMainLayoutWidget() {
    return MaterialApp(
      home: BlocProvider<ThemeCubit>.value(
        value: mockThemeCubit,
        child: const MainLayoutPage(),
      ),
    );
  }

  testWidgets('renders loading state', (tester) async {
    when(() => mockCubit.state).thenReturn(CustomersLoading());

    when(
      () => mockCubit.fetchCustomers(searchQuery: any(named: 'searchQuery')),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Loading Customer Name'), findsWidgets);
  });

  testWidgets('renders success state with list', (tester) async {
    final customers = [
      const CustomerModel(
        id: 1,
        name: 'Acme',
        phone: '123',
        city: 'City',
        email: 'e',
        address: 'a',
      ),
    ];
    when(() => mockCubit.state).thenReturn(CustomersSuccess(customers));
    when(
      () => mockCubit.fetchCustomers(searchQuery: any(named: 'searchQuery')),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Acme'), findsOneWidget);
    expect(find.text('123'), findsOneWidget);
  });

  testWidgets('shows Sales Orders navigation tab for internal user', (
    tester,
  ) async {
    when(() => mockSessionManager.currentUser).thenReturn(
      const AuthSessionModel(
        uid: 1,
        database: 'db',
        username: 'user',
        password: 'pass',
        isInternalUser: true,
      ),
    );
    when(() => mockCubit.state).thenReturn(CustomersSuccess(const []));
    when(
      () => mockCubit.fetchCustomers(searchQuery: any(named: 'searchQuery')),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(buildMainLayoutWidget());

    expect(find.text('Sales'), findsOneWidget);
  });

  testWidgets('hides Sales Orders navigation tab for non-internal user', (
    tester,
  ) async {
    when(() => mockSessionManager.currentUser).thenReturn(
      const AuthSessionModel(
        uid: 1,
        database: 'db',
        username: 'user',
        password: 'pass',
        isInternalUser: false,
      ),
    );
    when(() => mockCubit.state).thenReturn(CustomersSuccess(const []));
    when(
      () => mockCubit.fetchCustomers(searchQuery: any(named: 'searchQuery')),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(buildMainLayoutWidget());

    expect(find.text('Sales'), findsNothing);
  });
}
