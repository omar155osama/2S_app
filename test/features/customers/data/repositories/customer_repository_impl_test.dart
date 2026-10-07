import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_odoo_app/core/errors/exceptions.dart';
import 'package:sales_odoo_app/core/errors/failures.dart';
import 'package:sales_odoo_app/core/network/network_info.dart';
import 'package:sales_odoo_app/features/customers/data/datasources/customer_local_datasource.dart';
import 'package:sales_odoo_app/features/customers/data/datasources/customer_remote_datasource.dart';
import 'package:sales_odoo_app/features/customers/data/models/customer_model.dart';
import 'package:sales_odoo_app/features/customers/data/repositories/customer_repository_impl.dart';

class MockCustomerRemoteDataSource extends Mock
    implements CustomerRemoteDataSource {}

class MockCustomerLocalDataSource extends Mock
    implements CustomerLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late CustomerRepositoryImpl repository;
  late MockCustomerRemoteDataSource mockRemoteDataSource;
  late MockCustomerLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockCustomerRemoteDataSource();
    mockLocalDataSource = MockCustomerLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = CustomerRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  const tCustomer = CustomerModel(
    id: 1,
    name: 'Acme',
    phone: '123',
    city: 'City',
    email: 'email@acme.com',
    address: 'Address',
  );

  test('should return list of customers online and cache them', () async {
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    when(
      () => mockRemoteDataSource.getCustomers(
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenAnswer((_) async => [tCustomer]);
    when(
      () => mockLocalDataSource.cacheCustomers(any()),
    ).thenAnswer((_) async => {});
    when(
      () => mockLocalDataSource.getPendingPhoneEdits(),
    ).thenAnswer((_) async => {});

    final result = await repository.getCustomers();

    expect(result.$1, isNull);
    expect(result.$2, [tCustomer]);
    verify(() => mockLocalDataSource.cacheCustomers([tCustomer])).called(1);
  });

  test('should return list of customers offline', () async {
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
    when(
      () => mockLocalDataSource.getCachedCustomers(),
    ).thenAnswer((_) async => [tCustomer]);

    final result = await repository.getCustomers();

    expect(result.$1, isNull);
    expect(result.$2, [tCustomer]);
  });

  test('should return ServerFailure on ServerException online', () async {
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    when(
      () => mockRemoteDataSource.getCustomers(
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenThrow(const ServerException('Error'));

    final result = await repository.getCustomers();

    expect(result.$1, isA<ServerFailure>());
    expect(result.$2, isNull);
  });

  test(
    'should preserve pending phone edit when fetching customers online',
    () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => mockRemoteDataSource.getCustomers(
          searchQuery: any(named: 'searchQuery'),
        ),
      ).thenAnswer((_) async => [tCustomer]);
      when(
        () => mockLocalDataSource.getPendingPhoneEdits(),
      ).thenAnswer((_) async => {1: '999999'});
      when(
        () => mockLocalDataSource.cacheCustomers(any()),
      ).thenAnswer((_) async => {});

      final result = await repository.getCustomers();

      expect(result.$1, isNull);
      expect(result.$2!.first.phone, '999999');
    },
  );

  test('updateCustomerPhone updates local cache and pending edits', () async {
    when(
      () => mockLocalDataSource.updateCachedCustomerPhone(1, '555'),
    ).thenAnswer((_) async {});
    when(
      () => mockLocalDataSource.savePendingPhoneEdit(1, '555'),
    ).thenAnswer((_) async {});
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    when(
      () => mockRemoteDataSource.updateCustomerPhone(1, '555'),
    ).thenAnswer((_) async {});
    when(
      () => mockLocalDataSource.removePendingPhoneEdit(1),
    ).thenAnswer((_) async {});

    final failure = await repository.updateCustomerPhone(1, '555');

    expect(failure, isNull);
    verify(
      () => mockLocalDataSource.updateCachedCustomerPhone(1, '555'),
    ).called(1);
    verify(() => mockLocalDataSource.savePendingPhoneEdit(1, '555')).called(1);
    verify(() => mockRemoteDataSource.updateCustomerPhone(1, '555')).called(1);
    verify(() => mockLocalDataSource.removePendingPhoneEdit(1)).called(1);
  });

  test(
    'updateCustomerPhone returns failure when remote update fails',
    () async {
      when(
        () => mockLocalDataSource.updateCachedCustomerPhone(1, '555'),
      ).thenAnswer((_) async {});
      when(
        () => mockLocalDataSource.savePendingPhoneEdit(1, '555'),
      ).thenAnswer((_) async {});
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => mockRemoteDataSource.updateCustomerPhone(1, '555'),
      ).thenThrow(const ServerException('Permission Denied'));

      final failure = await repository.updateCustomerPhone(1, '555');

      expect(failure, isA<ServerFailure>());
      expect(failure!.message, 'Permission Denied');
    },
  );
}
