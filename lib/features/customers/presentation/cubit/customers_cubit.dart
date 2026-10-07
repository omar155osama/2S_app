import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_odoo_app/core/network/offline_sync_manager.dart';
import 'package:sales_odoo_app/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:sales_odoo_app/features/customers/presentation/cubit/customers_state.dart';

class CustomersCubit extends Cubit<CustomersState> {
  final CustomerRepository repository;
  final OfflineSyncManager? offlineSyncManager;
  StreamSubscription<void>? _syncSubscription;

  CustomersCubit({required this.repository, this.offlineSyncManager})
    : super(CustomersInitial()) {
    _syncSubscription = offlineSyncManager?.onSyncCompleted.listen((_) {
      _onSyncCompleted();
    });
  }

  void _onSyncCompleted() {
    final currentState = state;
    if (currentState is CustomerDetailSuccess) {
      fetchCustomerDetails(currentState.customer.id);
    } else if (currentState is CustomersSuccess) {
      fetchCustomers();
    }
  }

  @override
  Future<void> close() {
    _syncSubscription?.cancel();
    return super.close();
  }

  Future<void> fetchCustomers({String? searchQuery}) async {
    emit(CustomersLoading());

    final result = await repository.getCustomers(searchQuery: searchQuery);
    final failure = result.$1;
    final customers = result.$2;

    if (failure != null) {
      emit(CustomersError(failure.message));
    } else if (customers != null) {
      if (customers.isEmpty) {
        emit(CustomersEmpty());
      } else {
        emit(CustomersSuccess(customers));
      }
    }
  }

  Future<void> fetchCustomerDetails(int id) async {
    emit(CustomerDetailLoading());

    final result = await repository.getCustomerById(id);
    final failure = result.$1;
    final customer = result.$2;

    if (failure != null) {
      emit(CustomerDetailError(failure.message));
    } else if (customer != null) {
      final isPending = await repository.hasPendingSync(id);
      emit(CustomerDetailSuccess(customer, isPendingSync: isPending));
    }
  }

  Future<void> updateCustomerPhone(int id, String phone) async {
    final currentState = state;
    if (currentState is CustomerDetailSuccess) {
      emit(CustomerDetailSaving(currentState.customer));

      final failure = await repository.updateCustomerPhone(id, phone);
      if (failure != null) {
        emit(CustomerDetailError(failure.message));
        // Reset back to old state after error
        emit(currentState);
      } else {
        // Fetch it again to ensure we have the updated state (could be pending offline)
        await fetchCustomerDetails(id);
      }
    }
  }

  Future<void> syncPendingEdits() async {
    await repository.syncPendingChanges();
  }
}
