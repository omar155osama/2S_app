import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sales_odoo_app/core/network/network_info.dart';
import 'package:sales_odoo_app/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:sales_odoo_app/features/sales_orders/data/repositories/sales_order_repository_impl.dart';

class OfflineSyncManager {
  final CustomerRepository customerRepository;
  final SalesOrderRepository salesOrderRepository;
  final Connectivity connectivity;
  final NetworkInfo networkInfo;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isSyncing = false;

  final StreamController<void> _syncCompletedController =
      StreamController<void>.broadcast();

  Stream<void> get onSyncCompleted => _syncCompletedController.stream;

  OfflineSyncManager({
    required this.customerRepository,
    required this.salesOrderRepository,
    required this.connectivity,
    required this.networkInfo,
  });

  void startListening() {
    _subscription?.cancel();
    _subscription = connectivity.onConnectivityChanged.listen((results) async {
      final isOnline = !results.contains(ConnectivityResult.none);
      if (isOnline) {
        // Brief pause to allow OS network socket & DNS resolution to stabilize
        await Future.delayed(const Duration(milliseconds: 500));
        await syncAllPendingActions();
      }
    });
  }

  Future<void> syncAllPendingActions() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      int attempts = 0;
      while (attempts < 3) {
        attempts++;
        if (await networkInfo.isConnected) {
          try {
            await customerRepository.syncPendingChanges();
            await salesOrderRepository.syncPendingConfirmations();
            _syncCompletedController.add(null);
            break;
          } catch (_) {
            if (attempts < 3) {
              await Future.delayed(const Duration(seconds: 1));
            }
          }
        } else {
          if (attempts < 3) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }
    } catch (_) {
      // Ignore background auto-sync errors
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _syncCompletedController.close();
  }
}
