import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sales_odoo_app/core/errors/exceptions.dart';
import 'package:sales_odoo_app/core/network/odoo_config.dart';
import 'package:sales_odoo_app/core/network/session_manager.dart';
import 'package:sales_odoo_app/features/sales_orders/data/models/sales_order_line_model.dart';
import 'package:sales_odoo_app/features/sales_orders/data/models/sales_order_model.dart';
import 'package:xml_rpc/client.dart' as xml_rpc;

abstract class SalesOrderRemoteDataSource {
  Future<List<SalesOrderModel>> getSalesOrders();
  Future<SalesOrderModel> getSalesOrder(int id);
  Future<List<SalesOrderLineModel>> getSalesOrderLines(List<int> lineIds);
  Future<void> confirmSalesOrder(int id);
}

class SalesOrderRemoteDataSourceImpl implements SalesOrderRemoteDataSource {
  final OdooConfig config;
  final SessionManager sessionManager;
  final http.Client client;

  SalesOrderRemoteDataSourceImpl({
    required this.config,
    required this.sessionManager,
    required this.client,
  });

  @override
  Future<List<SalesOrderModel>> getSalesOrders() async {
    final session = sessionManager.currentUser;
    if (session == null || !session.isInternalUser) {
      throw const AuthException(
        'Session expired or user is not an internal user.',
      );
    }

    try {
      final url = Uri.parse('${config.baseUrl}/xmlrpc/2/object');
      final result = await xml_rpc.call(url, 'execute_kw', [
        session.database,
        session.uid,
        session.password,
        'sale.order',
        'search_read',
        [[]],
        {
          'fields': [
            'id',
            'name',
            'partner_id',
            'date_order',
            'state',
            'amount_total',
            'order_line',
          ],
          'limit': 80,
        },
      ], httpPost: client.post);

      if (result is List) {
        return result
            .map(
              (e) =>
                  SalesOrderModel.fromMap(Map<String, dynamic>.from(e as Map)),
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
        'Unexpected error occurred while fetching sales orders.',
      );
    }
  }

  @override
  Future<SalesOrderModel> getSalesOrder(int id) async {
    final session = sessionManager.currentUser;
    if (session == null || !session.isInternalUser) {
      throw const AuthException(
        'Session expired or user is not an internal user.',
      );
    }

    try {
      final url = Uri.parse('${config.baseUrl}/xmlrpc/2/object');
      final result = await xml_rpc.call(url, 'execute_kw', [
        session.database,
        session.uid,
        session.password,
        'sale.order',
        'search_read',
        [
          [
            ['id', '=', id],
          ],
        ],
        {
          'fields': [
            'id',
            'name',
            'partner_id',
            'date_order',
            'state',
            'amount_total',
            'order_line',
          ],
          'limit': 1,
        },
      ], httpPost: client.post);

      if (result is List && result.isNotEmpty) {
        return SalesOrderModel.fromMap(
          Map<String, dynamic>.from(result.first as Map),
        );
      }
      throw const ServerException('Sales order not found.');
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
        'Unexpected error occurred while fetching sales order details.',
      );
    }
  }

  @override
  Future<List<SalesOrderLineModel>> getSalesOrderLines(
    List<int> lineIds,
  ) async {
    if (lineIds.isEmpty) return [];

    final session = sessionManager.currentUser;
    if (session == null || !session.isInternalUser) {
      throw const AuthException(
        'Session expired or user is not an internal user.',
      );
    }

    try {
      final url = Uri.parse('${config.baseUrl}/xmlrpc/2/object');
      final result = await xml_rpc.call(url, 'execute_kw', [
        session.database,
        session.uid,
        session.password,
        'sale.order.line',
        'search_read',
        [
          [
            ['id', 'in', lineIds],
          ],
        ],
        {
          'fields': [
            'id',
            'product_id',
            'name',
            'product_uom_qty',
            'price_unit',
            'price_subtotal',
          ],
        },
      ], httpPost: client.post);

      if (result is List) {
        return result
            .map(
              (e) => SalesOrderLineModel.fromMap(
                Map<String, dynamic>.from(e as Map),
              ),
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
        'Unexpected error occurred while fetching sales order lines.',
      );
    }
  }

  @override
  Future<void> confirmSalesOrder(int id) async {
    final session = sessionManager.currentUser;
    if (session == null || !session.isInternalUser) {
      throw const AuthException(
        'Session expired or user is not an internal user.',
      );
    }

    try {
      final url = Uri.parse('${config.baseUrl}/xmlrpc/2/object');
      await xml_rpc.call(url, 'execute_kw', [
        session.database,
        session.uid,
        session.password,
        'sale.order',
        'action_confirm',
        [
          [id],
        ],
      ], httpPost: client.post);
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
        'Unexpected error occurred while confirming order.',
      );
    }
  }
}
