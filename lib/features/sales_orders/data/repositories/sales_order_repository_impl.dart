import 'package:sales_odoo_app/core/errors/exceptions.dart';
import 'package:sales_odoo_app/core/errors/failures.dart';
import 'package:sales_odoo_app/core/network/network_info.dart';
import 'package:sales_odoo_app/features/sales_orders/data/datasources/sales_order_local_datasource.dart';
import 'package:sales_odoo_app/features/sales_orders/data/datasources/sales_order_remote_datasource.dart';
import 'package:sales_odoo_app/features/sales_orders/data/models/sales_order_line_model.dart';
import 'package:sales_odoo_app/features/sales_orders/data/models/sales_order_model.dart';

abstract class SalesOrderRepository {
  Future<(Failure?, List<SalesOrderModel>?)> getSalesOrders();
  Future<(Failure?, SalesOrderModel?)> getSalesOrder(int id);
  Future<(Failure?, List<SalesOrderLineModel>?)> getSalesOrderLines(
    List<int> lineIds,
  );
  Future<Failure?> confirmSalesOrder(int id);
  Future<bool> hasPendingConfirmation(int id);
  Future<void> syncPendingConfirmations();
}

class SalesOrderRepositoryImpl implements SalesOrderRepository {
  final SalesOrderRemoteDataSource remoteDataSource;
  final SalesOrderLocalDataSource? localDataSource;
  final NetworkInfo networkInfo;

  SalesOrderRepositoryImpl({
    required this.remoteDataSource,
    this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<(Failure?, List<SalesOrderModel>?)> getSalesOrders() async {
    if (await networkInfo.isConnected) {
      try {
        final orders = await remoteDataSource.getSalesOrders();
        await localDataSource?.cacheSalesOrders(orders);
        return (null, orders);
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
      if (localDataSource != null) {
        try {
          final cachedOrders = await localDataSource!.getCachedSalesOrders();
          if (cachedOrders.isNotEmpty) {
            return (null, cachedOrders);
          }
        } catch (_) {}
      }
      return (
        const NetworkFailure(
          'No internet connection. Sales Orders require a network connection.',
        ),
        null,
      );
    }
  }

  @override
  Future<(Failure?, SalesOrderModel?)> getSalesOrder(int id) async {
    if (await networkInfo.isConnected) {
      try {
        final order = await remoteDataSource.getSalesOrder(id);
        await localDataSource?.updateCachedSalesOrderState(id, order.state);
        return (null, order);
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
      if (localDataSource != null) {
        try {
          final cachedOrder = await localDataSource!.getCachedSalesOrder(id);
          if (cachedOrder != null) {
            return (null, cachedOrder);
          }
        } catch (_) {}
      }
      return (const NetworkFailure('No internet connection.'), null);
    }
  }

  @override
  Future<(Failure?, List<SalesOrderLineModel>?)> getSalesOrderLines(
    List<int> lineIds,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final lines = await remoteDataSource.getSalesOrderLines(lineIds);
        return (null, lines);
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
      return (const NetworkFailure('No internet connection.'), null);
    }
  }

  @override
  Future<Failure?> confirmSalesOrder(int id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.confirmSalesOrder(id);
        await localDataSource?.updateCachedSalesOrderState(id, 'sale');
        await localDataSource?.removePendingConfirmation(id);
        return null;
      } on AuthException catch (e) {
        return ServerFailure(e.message);
      } on ServerException catch (e) {
        return ServerFailure(e.message);
      } on NetworkException {
        await localDataSource?.savePendingConfirmation(id);
        return null;
      } catch (e) {
        return const ServerFailure('An unexpected error occurred.');
      }
    } else {
      await localDataSource?.savePendingConfirmation(id);
      return null;
    }
  }

  @override
  Future<bool> hasPendingConfirmation(int id) async {
    return await localDataSource?.hasPendingConfirmation(id) ?? false;
  }

  @override
  Future<void> syncPendingConfirmations() async {
    if (await networkInfo.isConnected && localDataSource != null) {
      final pendingIds = await localDataSource!.getPendingConfirmations();
      for (final id in pendingIds) {
        try {
          await remoteDataSource.confirmSalesOrder(id);
          await localDataSource!.updateCachedSalesOrderState(id, 'sale');
          await localDataSource!.removePendingConfirmation(id);
        } catch (_) {
          continue;
        }
      }
    }
  }
}
