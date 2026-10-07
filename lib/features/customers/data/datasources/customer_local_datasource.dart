import 'dart:convert';
import 'package:sales_odoo_app/features/customers/data/models/customer_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class CustomerLocalDataSource {
  Future<void> cacheCustomers(List<CustomerModel> customers);
  Future<List<CustomerModel>> getCachedCustomers();
  Future<CustomerModel?> getCachedCustomer(int id);
  Future<void> updateCachedCustomerPhone(int id, String newPhone);
  Future<void> savePendingPhoneEdit(int id, String newPhone);
  Future<Map<int, String>> getPendingPhoneEdits();
  Future<void> removePendingPhoneEdit(int id);
}

class CustomerLocalDataSourceImpl implements CustomerLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String cachedCustomersKey = 'CACHED_CUSTOMERS';
  static const String pendingPhoneEditsKey = 'PENDING_PHONE_EDITS';

  CustomerLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheCustomers(List<CustomerModel> customers) async {
    final pendingEdits = await getPendingPhoneEdits();

    final updatedCustomers = customers.map((c) {
      if (pendingEdits.containsKey(c.id)) {
        return c.copyWith(phone: pendingEdits[c.id]);
      }
      return c;
    }).toList();

    final List<Map<String, dynamic>> jsonList = updatedCustomers
        .map((c) => c.toMap())
        .toList();
    await sharedPreferences.setString(
      cachedCustomersKey,
      json.encode(jsonList),
    );
  }

  @override
  Future<List<CustomerModel>> getCachedCustomers() async {
    final jsonString = sharedPreferences.getString(cachedCustomersKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((item) => CustomerModel.fromCache(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<CustomerModel?> getCachedCustomer(int id) async {
    final customers = await getCachedCustomers();
    try {
      return customers.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateCachedCustomerPhone(int id, String newPhone) async {
    final customers = await getCachedCustomers();
    final index = customers.indexWhere((c) => c.id == id);
    if (index != -1) {
      final updatedCustomer = customers[index].copyWith(phone: newPhone);
      customers[index] = updatedCustomer;
      await cacheCustomers(customers);
    }
  }

  @override
  Future<void> savePendingPhoneEdit(int id, String newPhone) async {
    final pendingEdits = await getPendingPhoneEdits();
    pendingEdits[id] = newPhone;
    await sharedPreferences.setString(
      pendingPhoneEditsKey,
      json.encode(
        pendingEdits.map((key, value) => MapEntry(key.toString(), value)),
      ),
    );
  }

  @override
  Future<Map<int, String>> getPendingPhoneEdits() async {
    final jsonString = sharedPreferences.getString(pendingPhoneEditsKey);
    if (jsonString != null) {
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;
      return jsonMap.map(
        (key, value) => MapEntry(int.parse(key), value as String),
      );
    }
    return {};
  }

  @override
  Future<void> removePendingPhoneEdit(int id) async {
    final pendingEdits = await getPendingPhoneEdits();
    if (pendingEdits.containsKey(id)) {
      pendingEdits.remove(id);
      await sharedPreferences.setString(
        pendingPhoneEditsKey,
        json.encode(
          pendingEdits.map((key, value) => MapEntry(key.toString(), value)),
        ),
      );
    }
  }
}
