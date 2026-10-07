import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:sales_odoo_app/core/errors/exceptions.dart';
import 'package:sales_odoo_app/core/network/odoo_config.dart';
import 'package:sales_odoo_app/features/auth/data/datasources/odoo_auth_datasource.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeUri extends Fake implements Uri {}

void main() {
  late OdooAuthDataSourceImpl dataSource;
  late MockHttpClient mockHttpClient;
  late OdooConfig config;

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    config = const OdooConfig(
      baseUrl: 'https://test.odoo.com',
      database: 'test_db',
    );
    dataSource = OdooAuthDataSourceImpl(config: config, client: mockHttpClient);
  });

  final String successXml = '''
<?xml version="1.0"?>
<methodResponse>
  <params>
    <param>
      <value><int>42</int></value>
    </param>
  </params>
</methodResponse>
''';

  final String failureXml = '''
<?xml version="1.0"?>
<methodResponse>
  <params>
    <param>
      <value><boolean>0</boolean></value>
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

  test('should return UID when authentication is successful', () async {
    when(
      () => mockHttpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
        encoding: any(named: 'encoding'),
      ),
    ).thenAnswer((_) async => http.Response(successXml, 200));

    final result = await dataSource.authenticate('user', 'pass');

    expect(result, 42);
  });

  test(
    'should throw AuthException when authentication fails (invalid credentials)',
    () async {
      when(
        () => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
          encoding: any(named: 'encoding'),
        ),
      ).thenAnswer((_) async => http.Response(failureXml, 200));

      expect(
        () => dataSource.authenticate('user', 'pass'),
        throwsA(isA<AuthException>()),
      );
    },
  );

  test('should throw ServerException on XML-RPC fault', () async {
    when(
      () => mockHttpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
        encoding: any(named: 'encoding'),
      ),
    ).thenAnswer((_) async => http.Response(faultXml, 200));

    expect(
      () => dataSource.authenticate('user', 'pass'),
      throwsA(isA<ServerException>()),
    );
  });

  final String boolTrueXml = '''
<?xml version="1.0"?>
<methodResponse>
  <params>
    <param>
      <value><boolean>1</boolean></value>
    </param>
  </params>
</methodResponse>
''';

  final String boolFalseXml = '''
<?xml version="1.0"?>
<methodResponse>
  <params>
    <param>
      <value><boolean>0</boolean></value>
    </param>
  </params>
</methodResponse>
''';

  test(
    'should return true when checkIsInternalUser receives boolean 1',
    () async {
      when(
        () => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
          encoding: any(named: 'encoding'),
        ),
      ).thenAnswer((_) async => http.Response(boolTrueXml, 200));

      final result = await dataSource.checkIsInternalUser(42, 'pass');

      expect(result, isTrue);
    },
  );

  test(
    'should return false when checkIsInternalUser receives boolean 0',
    () async {
      when(
        () => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
          encoding: any(named: 'encoding'),
        ),
      ).thenAnswer((_) async => http.Response(boolFalseXml, 200));

      final result = await dataSource.checkIsInternalUser(42, 'pass');

      expect(result, isFalse);
    },
  );
}
