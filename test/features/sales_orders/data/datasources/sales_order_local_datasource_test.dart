import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_odoo_app/features/sales_orders/data/datasources/sales_order_local_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late SalesOrderLocalDataSourceImpl dataSource;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    dataSource = SalesOrderLocalDataSourceImpl(sharedPreferences: mockPrefs);
  });

  test(
    'savePendingConfirmation persists order id to SharedPreferences',
    () async {
      when(() => mockPrefs.getString(any())).thenReturn(null);
      when(
        () => mockPrefs.setString(any(), any()),
      ).thenAnswer((_) async => true);

      await dataSource.savePendingConfirmation(42);

      verify(
        () => mockPrefs.setString(
          SalesOrderLocalDataSourceImpl.pendingConfirmationsKey,
          '[42]',
        ),
      ).called(1);
    },
  );

  test(
    'removePendingConfirmation removes order id from SharedPreferences',
    () async {
      when(() => mockPrefs.getString(any())).thenReturn('[42, 99]');
      when(
        () => mockPrefs.setString(any(), any()),
      ).thenAnswer((_) async => true);

      await dataSource.removePendingConfirmation(42);

      verify(
        () => mockPrefs.setString(
          SalesOrderLocalDataSourceImpl.pendingConfirmationsKey,
          '[99]',
        ),
      ).called(1);
    },
  );
}
