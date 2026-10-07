import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_odoo_app/features/customers/data/models/customer_model.dart';
import 'package:sales_odoo_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:sales_odoo_app/features/customers/presentation/cubit/customers_state.dart';
import 'package:sales_odoo_app/features/customers/presentation/pages/customer_details_page.dart';
import 'package:bloc_test/bloc_test.dart';

class MockCustomersCubit extends MockCubit<CustomersState>
    implements CustomersCubit {}

void main() {
  late MockCustomersCubit mockCubit;

  setUp(() {
    mockCubit = MockCustomersCubit();
    GetIt.I.registerFactory<CustomersCubit>(() => mockCubit);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  Widget buildTestWidget() {
    return const MaterialApp(home: CustomerDetailsPage(customerId: 1));
  }

  final tCustomer = const CustomerModel(
    id: 1,
    name: 'Acme',
    phone: '123',
    city: 'City',
    email: 'email',
    address: 'address',
  );

  testWidgets('renders loading state', (tester) async {
    when(() => mockCubit.state).thenReturn(CustomerDetailLoading());
    when(() => mockCubit.fetchCustomerDetails(1)).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Loading Customer Name'), findsOneWidget);
  });

  testWidgets('renders success state and pending sync alert', (tester) async {
    when(
      () => mockCubit.state,
    ).thenReturn(CustomerDetailSuccess(tCustomer, isPendingSync: true));
    when(() => mockCubit.fetchCustomerDetails(1)).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Acme'), findsOneWidget);
    expect(find.text('Saved offline — waiting for sync'), findsOneWidget);
  });

  testWidgets('phone is editable and save button works', (tester) async {
    when(
      () => mockCubit.state,
    ).thenReturn(CustomerDetailSuccess(tCustomer, isPendingSync: false));
    when(() => mockCubit.fetchCustomerDetails(1)).thenAnswer((_) async {});
    when(
      () => mockCubit.updateCustomerPhone(1, '456'),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('123'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save'));
    await tester.enterText(find.byType(TextField), '456');
    await tester.tap(find.text('Save'));
    await tester.pump();

    verify(() => mockCubit.updateCustomerPhone(1, '456')).called(1);
  });
}
