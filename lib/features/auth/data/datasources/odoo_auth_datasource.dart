import 'dart:io';
import 'package:sales_odoo_app/core/errors/exceptions.dart';
import 'package:sales_odoo_app/core/network/odoo_config.dart';
import 'package:xml_rpc/client.dart' as xml_rpc;
import 'package:http/http.dart' as http;

abstract class OdooAuthDataSource {
  Future<int> authenticate(String username, String password);
  Future<bool> checkIsInternalUser(int uid, String password);
}

class OdooAuthDataSourceImpl implements OdooAuthDataSource {
  final OdooConfig config;
  final http.Client client;

  OdooAuthDataSourceImpl({required this.config, required this.client});

  @override
  Future<int> authenticate(String username, String password) async {
    try {
      final url = Uri.parse('${config.baseUrl}/xmlrpc/2/common');

      final result = await xml_rpc.call(url, 'authenticate', [
        config.database,
        username,
        password,
        <String, dynamic>{},
      ], httpPost: client.post);

      if (result == null || result == false) {
        throw const AuthException('Invalid username or password.');
      }

      if (result is int) {
        return result;
      }

      throw const ServerException('Unexpected response format from Odoo.');
    } on xml_rpc.Fault catch (_) {
      throw const ServerException(
        'Unable to contact Odoo right now. Please try again.',
      );
    } on SocketException catch (_) {
      throw const NetworkException(
        'Unable to connect to Odoo. Please check your connection.',
      );
    } catch (e) {
      if (e is AuthException || e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw const ServerException(
        'Unable to contact Odoo right now. Please try again.',
      );
    }
  }

  @override
  Future<bool> checkIsInternalUser(int uid, String password) async {
    try {
      final url = Uri.parse('${config.baseUrl}/xmlrpc/2/object');
      final result = await xml_rpc.call(url, 'execute_kw', [
        config.database,
        uid,
        password,
        'res.users',
        'has_group',
        [
          [uid],
          'base.group_user',
        ],
      ], httpPost: client.post);

      if (result is bool) {
        return result;
      }
      return false;
    } on xml_rpc.Fault catch (e) {
      throw ServerException('Unable to verify user permissions: ${e.text}');
    } on SocketException catch (_) {
      throw const NetworkException(
        'Unable to connect to Odoo. Please check your connection.',
      );
    } catch (e) {
      if (e is AuthException || e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw const ServerException(
        'Unexpected error occurred while verifying user permissions.',
      );
    }
  }
}
