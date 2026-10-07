import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sales_odoo_app/core/errors/exceptions.dart';
import 'package:sales_odoo_app/core/network/odoo_config.dart';
import 'package:sales_odoo_app/core/network/session_manager.dart';
import 'package:sales_odoo_app/features/customers/data/models/customer_model.dart';
import 'package:xml_rpc/client.dart' as xml_rpc;

abstract class CustomerRemoteDataSource {
  Future<List<CustomerModel>> getCustomers({String? searchQuery});
  Future<CustomerModel> getCustomerById(int id);
  Future<void> updateCustomerPhone(int id, String phone);
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final OdooConfig config;
  final http.Client client;
  final SessionManager sessionManager;

  CustomerRemoteDataSourceImpl({
    required this.config,
    required this.client,
    required this.sessionManager,
  });

  @override
  Future<List<CustomerModel>> getCustomers({String? searchQuery}) async {
    final session = sessionManager.currentUser;
    if (session == null) {
      throw const AuthException(
        'Session expired or not found. Please login again.',
      );
    }

    try {
      final url = Uri.parse('${config.baseUrl}/xmlrpc/2/object');

      final domain = [
        ['customer_rank', '>', 0],
      ];

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        domain.add(['name', 'ilike', searchQuery.trim()]);
      }

      final result = await xml_rpc.call(url, 'execute_kw', [
        session.database,
        session.uid,
        session.password,
        'res.partner',
        'search_read',
        [domain],
        <String, dynamic>{
          'fields': [
            'id',
            'name',
            'phone',
            'city',
            'email',
            'street',
            'state_id',
            'country_id',
          ],
          'limit': 80, // reasonable limit as per instructions
        },
      ], httpPost: client.post);

      if (result is List) {
        return result
            .map(
              (item) =>
                  CustomerModel.fromMap(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      }
      return [];
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
        'Unexpected error occurred while fetching customers.',
      );
    }
  }

  @override
  Future<CustomerModel> getCustomerById(int id) async {
    final session = sessionManager.currentUser;
    if (session == null) {
      throw const AuthException(
        'Session expired or not found. Please login again.',
      );
    }

    try {
      final url = Uri.parse('${config.baseUrl}/xmlrpc/2/object');

      final result = await xml_rpc.call(url, 'execute_kw', [
        session.database,
        session.uid,
        session.password,
        'res.partner',
        'search_read',
        [
          [
            ['id', '=', id],
          ],
        ],
        <String, dynamic>{
          'fields': [
            'id',
            'name',
            'phone',
            'city',
            'email',
            'street',
            'state_id',
            'country_id',
          ],
        },
      ], httpPost: client.post);

      if (result is List && result.isNotEmpty) {
        return CustomerModel.fromMap(
          Map<String, dynamic>.from(result.first as Map),
        );
      }
      throw const ServerException('Customer not found.');
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
        'Unexpected error occurred while fetching customer details.',
      );
    }
  }

  @override
  Future<void> updateCustomerPhone(int id, String phone) async {
    final session = sessionManager.currentUser;
    if (session == null) {
      throw const AuthException(
        'Session expired or not found. Please login again.',
      );
    }

    try {
      final url = Uri.parse('${config.baseUrl}/xmlrpc/2/object');

      final result = await xml_rpc.call(url, 'execute_kw', [
        session.database,
        session.uid,
        session.password,
        'res.partner',
        'write',
        [
          [id],
          {'phone': phone},
        ],
      ], httpPost: client.post);

      if (result == false) {
        throw const ServerException(
          'Failed to update phone number. Access denied or record deleted.',
        );
      }
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
        'Unexpected error occurred while updating customer.',
      );
    }
  }
}
