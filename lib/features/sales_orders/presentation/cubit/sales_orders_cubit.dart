import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_odoo_app/core/network/offline_sync_manager.dart';
import 'package:sales_odoo_app/features/sales_orders/data/repositories/sales_order_repository_impl.dart';
import 'package:sales_odoo_app/features/sales_orders/presentation/cubit/sales_orders_state.dart';

class SalesOrdersCubit extends Cubit<SalesOrdersState> {
  final SalesOrderRepository repository;
  final OfflineSyncManager? offlineSyncManager;
  StreamSubscription<void>? _syncSubscription;

  SalesOrdersCubit({required this.repository, this.offlineSyncManager})
    : super(SalesOrdersInitial()) {
    _syncSubscription = offlineSyncManager?.onSyncCompleted.listen((_) {
      _onSyncCompleted();
    });
  }

  void _onSyncCompleted() {
    final currentState = state;
    if (currentState is SalesOrderDetailSuccess) {
      fetchSalesOrderDetails(currentState.order.id);
    } else if (currentState is SalesOrderConfirming) {
      fetchSalesOrderDetails(currentState.order.id);
    } else {
      fetchSalesOrders();
    }
  }

  @override
  Future<void> close() {
    _syncSubscription?.cancel();
    return super.close();
  }

  Future<void> fetchSalesOrders() async {
    emit(SalesOrdersLoading());

    final result = await repository.getSalesOrders();
    final failure = result.$1;
    final orders = result.$2;

    if (failure != null) {
      emit(SalesOrdersError(failure.message));
    } else if (orders != null && orders.isNotEmpty) {
      emit(SalesOrdersSuccess(orders));
    } else {
      emit(SalesOrdersEmpty());
    }
  }

  Future<void> fetchSalesOrderDetails(int id) async {
    emit(SalesOrderDetailLoading());

    final result = await repository.getSalesOrder(id);
    final failure = result.$1;
    final order = result.$2;

    if (failure != null) {
      emit(SalesOrderDetailError(failure.message));
      return;
    }

    if (order != null) {
      final linesResult = await repository.getSalesOrderLines(
        order.orderLineIds,
      );
      final isPending = await repository.hasPendingConfirmation(id);
      emit(
        SalesOrderDetailSuccess(
          order,
          linesResult.$2 ?? [],
          isPendingConfirmation: isPending,
        ),
      );
    }
  }

  Future<void> confirmSalesOrder(int id) async {
    final currentState = state;
    if (currentState is SalesOrderDetailSuccess) {
      emit(SalesOrderConfirming(currentState.order, currentState.lines));

      final failure = await repository.confirmSalesOrder(id);
      if (failure != null) {
        emit(SalesOrderDetailError(failure.message));
        emit(currentState);
      } else {
        await fetchSalesOrderDetails(id);
      }
    }
  }
}
