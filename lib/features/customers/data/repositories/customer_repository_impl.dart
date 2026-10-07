import 'package:sales_odoo_app/core/errors/exceptions.dart';
import 'package:sales_odoo_app/core/errors/failures.dart';
import 'package:sales_odoo_app/core/network/network_info.dart';
import 'package:sales_odoo_app/features/customers/data/datasources/customer_local_datasource.dart';
import 'package:sales_odoo_app/features/customers/data/datasources/customer_remote_datasource.dart';
import 'package:sales_odoo_app/features/customers/data/models/customer_model.dart';

abstract class CustomerRepository {
  Future<(Failure?, List<CustomerModel>?)> getCustomers({String? searchQuery});
  Future<(Failure?, CustomerModel?)> getCustomerById(int id);
  Future<Failure?> updateCustomerPhone(int id, String phone);
  Future<bool> hasPendingSync(int id);
  Future<void> syncPendingChanges();
}

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;
  final CustomerLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  CustomerRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<(Failure?, List<CustomerModel>?)> getCustomers({
    String? searchQuery,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final customers = await remoteDataSource.getCustomers(
          searchQuery: searchQuery,
        );

        // Cache customers only if it's not a search query or if you want to cache search results.
        // Instructions: "When customers are successfully fetched online: persist the customer list locally"
        // It's safer to only cache the full list (empty search query) to not overwrite the cache with a subset,
        // OR we can just merge. For simplicity, we'll cache if searchQuery is empty.
        final pendingEdits = await localDataSource.getPendingPhoneEdits();
        final updatedCustomers = customers.map((c) {
          if (pendingEdits.containsKey(c.id)) {
            return c.copyWith(phone: pendingEdits[c.id]);
          }
          return c;
        }).toList();

        if (searchQuery == null || searchQuery.isEmpty) {
          await localDataSource.cacheCustomers(updatedCustomers);
        }
        return (null, updatedCustomers);
      } on AuthException catch (e) {
        return (ServerFailure(e.message), null);
      } on ServerException catch (e) {
        return (ServerFailure(e.message), null);
      } on NetworkException catch (e) {
        return (NetworkFailure(e.message), null);
      } catch (e) {
        return (const ServerFailure('An unexpected error occurred.'), null);
      }
    } else {
      // Offline: retrieve from local cache
      try {
        final localCustomers = await localDataSource.getCachedCustomers();
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          final filtered = localCustomers
              .where((c) => c.name.toLowerCase().contains(query))
              .toList();
          return (null, filtered);
        }
        return (null, localCustomers);
      } catch (e) {
        return (const ServerFailure('Failed to load cached customers.'), null);
      }
    }
  }

  @override
  Future<(Failure?, CustomerModel?)> getCustomerById(int id) async {
    if (await networkInfo.isConnected) {
      try {
        var customer = await remoteDataSource.getCustomerById(id);

        final pendingEdits = await localDataSource.getPendingPhoneEdits();
        if (pendingEdits.containsKey(id)) {
          customer = customer.copyWith(phone: pendingEdits[id]);
        }

        return (null, customer);
      } on AuthException catch (e) {
        return (ServerFailure(e.message), null);
      } on ServerException catch (e) {
        return (ServerFailure(e.message), null);
      } on NetworkException catch (e) {
        return (NetworkFailure(e.message), null);
      } catch (e) {
        return (const ServerFailure('An unexpected error occurred.'), null);
      }
    } else {
      // Offline
      try {
        final localCustomer = await localDataSource.getCachedCustomer(id);
        if (localCustomer != null) {
          return (null, localCustomer);
        } else {
          return (const ServerFailure('Customer not found in cache.'), null);
        }
      } catch (e) {
        return (const ServerFailure('Failed to load cached customer.'), null);
      }
    }
  }

  @override
  Future<Failure?> updateCustomerPhone(int id, String phone) async {
    // 1. Always update local cache and save as pending
    try {
      await localDataSource.updateCachedCustomerPhone(id, phone);
      await localDataSource.savePendingPhoneEdit(id, phone);
    } catch (_) {
      return const ServerFailure('Failed to save edit locally.');
    }

    // 2. If online, try to sync immediately
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateCustomerPhone(id, phone);
        await localDataSource.removePendingPhoneEdit(id);
        return null;
      } on AuthException catch (e) {
        return ServerFailure(e.message);
      } on ServerException catch (e) {
        return ServerFailure(e.message);
      } on NetworkException {
        // Just remain pending
        return null;
      } catch (e) {
        return const ServerFailure('An unexpected error occurred.');
      }
    }

    // Offline: it remains pending
    return null;
  }

  @override
  Future<bool> hasPendingSync(int id) async {
    final pendingEdits = await localDataSource.getPendingPhoneEdits();
    return pendingEdits.containsKey(id);
  }

  @override
  Future<void> syncPendingChanges() async {
    if (await networkInfo.isConnected) {
      final pendingEdits = await localDataSource.getPendingPhoneEdits();
      for (final entry in pendingEdits.entries) {
        try {
          await remoteDataSource.updateCustomerPhone(entry.key, entry.value);
          await localDataSource.removePendingPhoneEdit(entry.key);
        } catch (e) {
          // Keep it pending if it fails
          continue;
        }
      }
    }
  }
}
