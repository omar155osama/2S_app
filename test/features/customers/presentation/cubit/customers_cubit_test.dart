import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_odoo_app/core/errors/failures.dart';
import 'package:sales_odoo_app/features/customers/data/models/customer_model.dart';
import 'package:sales_odoo_app/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:sales_odoo_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:sales_odoo_app/features/customers/presentation/cubit/customers_state.dart';

class MockCustomerRepository extends Mock implements CustomerRepository {}

void main() {
  late CustomersCubit cubit;
  late MockCustomerRepository mockRepository;

  setUp(() {
    mockRepository = MockCustomerRepository();
    cubit = CustomersCubit(repository: mockRepository);
  });

  const tCustomer = CustomerModel(
    id: 1,
    name: 'Acme',
    phone: '123',
    city: 'City',
    email: 'email',
    address: 'Address',
  );

  test('initial state should be CustomersInitial', () {
    expect(cubit.state, isA<CustomersInitial>());
  });

  blocTest<CustomersCubit, CustomersState>(
    'emits [CustomersLoading, CustomersSuccess] on fetch success',
    build: () {
      when(
        () =>
            mockRepository.getCustomers(searchQuery: any(named: 'searchQuery')),
      ).thenAnswer((_) async => (null, [tCustomer]));
      return cubit;
    },
    act: (cubit) => cubit.fetchCustomers(),
    expect: () => [isA<CustomersLoading>(), isA<CustomersSuccess>()],
  );

  blocTest<CustomersCubit, CustomersState>(
    'emits [CustomersLoading, CustomersEmpty] on empty fetch',
    build: () {
      when(
        () =>
            mockRepository.getCustomers(searchQuery: any(named: 'searchQuery')),
      ).thenAnswer((_) async => (null, <CustomerModel>[]));
      return cubit;
    },
    act: (cubit) => cubit.fetchCustomers(),
    expect: () => [isA<CustomersLoading>(), isA<CustomersEmpty>()],
  );

  blocTest<CustomersCubit, CustomersState>(
    'emits [CustomersLoading, CustomersError] on fetch error',
    build: () {
      when(
        () =>
            mockRepository.getCustomers(searchQuery: any(named: 'searchQuery')),
      ).thenAnswer((_) async => (const ServerFailure('Error'), null));
      return cubit;
    },
    act: (cubit) => cubit.fetchCustomers(),
    expect: () => [isA<CustomersLoading>(), isA<CustomersError>()],
  );
}
