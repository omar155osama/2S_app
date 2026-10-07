import 'package:sales_odoo_app/core/errors/exceptions.dart';
import 'package:sales_odoo_app/core/errors/failures.dart';
import 'package:sales_odoo_app/features/auth/data/datasources/odoo_auth_datasource.dart';
import 'package:sales_odoo_app/features/auth/data/models/auth_session_model.dart';
import 'package:sales_odoo_app/core/network/odoo_config.dart';

abstract class AuthRepository {
  Future<(Failure?, AuthSessionModel?)> login(String username, String password);
}

class AuthRepositoryImpl implements AuthRepository {
  final OdooAuthDataSource dataSource;
  final OdooConfig config;

  AuthRepositoryImpl({required this.dataSource, required this.config});

  @override
  Future<(Failure?, AuthSessionModel?)> login(
    String username,
    String password,
  ) async {
    try {
      final uid = await dataSource.authenticate(username, password);
      final isInternal = await dataSource.checkIsInternalUser(uid, password);

      final session = AuthSessionModel(
        uid: uid,
        database: config.database,
        username: username,
        password: password,
        isInternalUser: isInternal,
      );

      return (null, session);
    } on AuthException catch (e) {
      return (ServerFailure(e.message), null);
    } on ServerException catch (e) {
      return (ServerFailure(e.message), null);
    } on NetworkException catch (e) {
      return (NetworkFailure(e.message), null);
    } catch (e) {
      return (const ServerFailure('An unexpected error occurred.'), null);
    }
  }
}
