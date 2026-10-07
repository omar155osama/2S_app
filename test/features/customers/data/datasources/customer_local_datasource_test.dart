import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_odoo_app/features/customers/data/datasources/customer_local_datasource.dart';
import 'package:sales_odoo_app/features/customers/data/models/customer_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late CustomerLocalDataSourceImpl dataSource;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();
    dataSource = CustomerLocalDataSourceImpl(
      sharedPreferences: mockSharedPreferences,
    );
  });

  const tCustomer = CustomerModel(
    id: 1,
    name: 'Acme',
    phone: '123',
    city: 'City',
    email: 'email',
    address: 'address',
  );

  test('should cache customers', () async {
    when(
      () => mockSharedPreferences.getString(
        CustomerLocalDataSourceImpl.pendingPhoneEditsKey,
      ),
    ).thenReturn(null);
    when(
      () => mockSharedPreferences.setString(any(), any()),
    ).thenAnswer((_) async => true);

    await dataSource.cacheCustomers([tCustomer]);

    verify(
      () => mockSharedPreferences.setString(
        CustomerLocalDataSourceImpl.cachedCustomersKey,
        json.encode([tCustomer.toMap()]),
      ),
    ).called(1);
  });

  test('should return cached customers', () async {
    when(
      () => mockSharedPreferences.getString(
        CustomerLocalDataSourceImpl.cachedCustomersKey,
      ),
    ).thenReturn(json.encode([tCustomer.toMap()]));

    final result = await dataSource.getCachedCustomers();

    expect(result, [tCustomer]);
  });
}
