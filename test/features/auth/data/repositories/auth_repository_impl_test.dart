import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_odoo_app/core/errors/exceptions.dart';
import 'package:sales_odoo_app/core/errors/failures.dart';
import 'package:sales_odoo_app/core/network/odoo_config.dart';
import 'package:sales_odoo_app/features/auth/data/datasources/odoo_auth_datasource.dart';
import 'package:sales_odoo_app/features/auth/data/repositories/auth_repository_impl.dart';

class MockOdooAuthDataSource extends Mock implements OdooAuthDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockOdooAuthDataSource mockDataSource;
  late OdooConfig config;

  setUp(() {
    mockDataSource = MockOdooAuthDataSource();
    config = const OdooConfig(baseUrl: 'test', database: 'test_db');
    repository = AuthRepositoryImpl(dataSource: mockDataSource, config: config);
  });

  const tUsername = 'user';
  const tPassword = 'password';

  test('should return session model when datasource succeeds', () async {
    when(
      () => mockDataSource.authenticate(tUsername, tPassword),
    ).thenAnswer((_) async => 42);
    when(
      () => mockDataSource.checkIsInternalUser(42, tPassword),
    ).thenAnswer((_) async => true);

    final result = await repository.login(tUsername, tPassword);

    expect(result.$1, isNull);
    expect(result.$2?.uid, 42);
    expect(result.$2?.database, 'test_db');
    expect(result.$2?.username, tUsername);
    expect(result.$2?.password, tPassword);
    expect(result.$2?.isInternalUser, true);
  });

  test(
    'should return ServerFailure when datasource throws AuthException',
    () async {
      when(
        () => mockDataSource.authenticate(tUsername, tPassword),
      ).thenThrow(const AuthException('Invalid'));

      final result = await repository.login(tUsername, tPassword);

      expect(result.$1, isA<ServerFailure>());
      expect(result.$2, isNull);
    },
  );

  test(
    'should return NetworkFailure when datasource throws NetworkException',
    () async {
      when(
        () => mockDataSource.authenticate(tUsername, tPassword),
      ).thenThrow(const NetworkException('No connection'));

      final result = await repository.login(tUsername, tPassword);

      expect(result.$1, isA<NetworkFailure>());
      expect(result.$2, isNull);
    },
  );
}
