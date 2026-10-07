import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:sales_odoo_app/core/errors/exceptions.dart';
import 'package:sales_odoo_app/core/network/odoo_config.dart';
import 'package:sales_odoo_app/core/network/session_manager.dart';
import 'package:sales_odoo_app/features/auth/data/models/auth_session_model.dart';
import 'package:sales_odoo_app/features/sales_orders/data/datasources/sales_order_remote_datasource.dart';

class MockSessionManager extends Mock implements SessionManager {}

class MockClient extends Mock implements http.Client {}

void main() {
  late SalesOrderRemoteDataSourceImpl dataSource;
  late MockSessionManager mockSessionManager;
  late MockClient mockClient;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockSessionManager = MockSessionManager();
    mockClient = MockClient();
    dataSource = SalesOrderRemoteDataSourceImpl(
      config: const OdooConfig(baseUrl: 'test', database: 'test_db'),
      sessionManager: mockSessionManager,
      client: mockClient,
    );
  });

  test('should throw AuthException if user is not internal', () async {
    when(() => mockSessionManager.currentUser).thenReturn(
      const AuthSessionModel(
        uid: 1,
        database: 'db',
        username: 'user',
        password: 'pwd',
        isInternalUser: false,
      ),
    );
    expect(() => dataSource.getSalesOrders(), throwsA(isA<AuthException>()));
  });
}
