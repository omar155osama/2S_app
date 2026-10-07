import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:sales_odoo_app/core/errors/exceptions.dart';
import 'package:sales_odoo_app/core/network/odoo_config.dart';
import 'package:sales_odoo_app/core/network/session_manager.dart';
import 'package:sales_odoo_app/features/auth/data/models/auth_session_model.dart';
import 'package:sales_odoo_app/features/customers/data/datasources/customer_remote_datasource.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockSessionManager extends Mock implements SessionManager {}

class FakeUri extends Fake implements Uri {}

void main() {
  late CustomerRemoteDataSourceImpl dataSource;
  late MockHttpClient mockHttpClient;
  late MockSessionManager mockSessionManager;
  late OdooConfig config;

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockSessionManager = MockSessionManager();
    config = const OdooConfig(
      baseUrl: 'https://test.odoo.com',
      database: 'test_db',
    );
    dataSource = CustomerRemoteDataSourceImpl(
      config: config,
      client: mockHttpClient,
      sessionManager: mockSessionManager,
    );

    when(() => mockSessionManager.currentUser).thenReturn(
      const AuthSessionModel(
        uid: 42,
        database: 'test_db',
        username: 'user',
        password: 'password',
        isInternalUser: true,
      ),
    );
  });

  final String successXml = '''
<?xml version="1.0"?>
<methodResponse>
  <params>
    <param>
      <value>
        <array>
          <data>
            <value>
              <struct>
                <member><name>id</name><value><int>1</int></value></member>
                <member><name>name</name><value><string>Acme Corp</string></value></member>
                <member><name>phone</name><value><string>123456</string></value></member>
                <member><name>city</name><value><string>Metropolis</string></value></member>
                <member><name>email</name><value><string>info@acme.com</string></value></member>
              </struct>
            </value>
          </data>
        </array>
      </value>
    </param>
  </params>
</methodResponse>
''';

  final String faultXml = '''
<?xml version="1.0"?>
<methodResponse>
  <fault>
    <value>
      <struct>
        <member>
          <name>faultCode</name>
          <value><int>4</int></value>
        </member>
        <member>
          <name>faultString</name>
          <value><string>Server Error</string></value>
        </member>
      </struct>
    </value>
  </fault>
</methodResponse>
''';

  test('should return list of customers on success', () async {
    when(
      () => mockHttpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
        encoding: any(named: 'encoding'),
      ),
    ).thenAnswer((_) async => http.Response(successXml, 200));

    final result = await dataSource.getCustomers();

    expect(result, isNotEmpty);
    expect(result.first.name, 'Acme Corp');
  });

  test('should return customer by id on success', () async {
    when(
      () => mockHttpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
        encoding: any(named: 'encoding'),
      ),
    ).thenAnswer((_) async => http.Response(successXml, 200));

    final result = await dataSource.getCustomerById(1);

    expect(result.name, 'Acme Corp');
  });

  test('should throw ServerException on XML-RPC fault', () async {
    when(
      () => mockHttpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
        encoding: any(named: 'encoding'),
      ),
    ).thenAnswer((_) async => http.Response(faultXml, 200));

    expect(() => dataSource.getCustomers(), throwsA(isA<ServerException>()));
  });

  test('should throw AuthException if session is null', () async {
    when(() => mockSessionManager.currentUser).thenReturn(null);
    expect(() => dataSource.getCustomers(), throwsA(isA<AuthException>()));
  });
}
