import 'dart:convert';
import 'package:sales_odoo_app/features/sales_orders/data/models/sales_order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SalesOrderLocalDataSource {
  Future<void> cacheSalesOrders(List<SalesOrderModel> orders);
  Future<List<SalesOrderModel>> getCachedSalesOrders();
  Future<SalesOrderModel?> getCachedSalesOrder(int id);
  Future<void> savePendingConfirmation(int id);
  Future<List<int>> getPendingConfirmations();
  Future<void> removePendingConfirmation(int id);
  Future<bool> hasPendingConfirmation(int id);
  Future<void> updateCachedSalesOrderState(int id, String newState);
}

class SalesOrderLocalDataSourceImpl implements SalesOrderLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String cachedSalesOrdersKey = 'CACHED_SALES_ORDERS';
  static const String pendingConfirmationsKey =
      'PENDING_SALES_ORDER_CONFIRMATIONS';

  SalesOrderLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheSalesOrders(List<SalesOrderModel> orders) async {
    final List<Map<String, dynamic>> jsonList = orders
        .map((o) => o.toMap())
        .toList();
    await sharedPreferences.setString(
      cachedSalesOrdersKey,
      json.encode(jsonList),
    );
  }

  @override
  Future<List<SalesOrderModel>> getCachedSalesOrders() async {
    final jsonString = sharedPreferences.getString(cachedSalesOrdersKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map(
            (item) =>
                SalesOrderModel.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    }
    return [];
  }

  @override
  Future<SalesOrderModel?> getCachedSalesOrder(int id) async {
    final orders = await getCachedSalesOrders();
    try {
      return orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePendingConfirmation(int id) async {
    final pending = await getPendingConfirmations();
    if (!pending.contains(id)) {
      pending.add(id);
      await sharedPreferences.setString(
        pendingConfirmationsKey,
        json.encode(pending),
      );
    }
  }

  @override
  Future<List<int>> getPendingConfirmations() async {
    final jsonString = sharedPreferences.getString(pendingConfirmationsKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList.map((e) => (e as num).toInt()).toList();
    }
    return [];
  }

  @override
  Future<void> removePendingConfirmation(int id) async {
    final pending = await getPendingConfirmations();
    if (pending.contains(id)) {
      pending.remove(id);
      await sharedPreferences.setString(
        pendingConfirmationsKey,
        json.encode(pending),
      );
    }
  }

  @override
  Future<bool> hasPendingConfirmation(int id) async {
    final pending = await getPendingConfirmations();
    return pending.contains(id);
  }

  @override
  Future<void> updateCachedSalesOrderState(int id, String newState) async {
    final orders = await getCachedSalesOrders();
    final index = orders.indexWhere((o) => o.id == id);
    if (index != -1) {
      orders[index] = orders[index].copyWith(state: newState);
      await cacheSalesOrders(orders);
    }
  }
}
