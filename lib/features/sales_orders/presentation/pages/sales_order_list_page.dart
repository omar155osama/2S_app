import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sales_odoo_app/core/di/injection.dart';
import 'package:sales_odoo_app/core/theme/app_theme.dart';
import 'package:sales_odoo_app/core/presentation/widgets/authenticated_app_bar.dart';
import 'package:sales_odoo_app/features/sales_orders/data/models/sales_order_model.dart';
import 'package:sales_odoo_app/features/sales_orders/presentation/cubit/sales_orders_cubit.dart';
import 'package:sales_odoo_app/features/sales_orders/presentation/cubit/sales_orders_state.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SalesOrderListPage extends StatefulWidget {
  const SalesOrderListPage({super.key});

  @override
  State<SalesOrderListPage> createState() => _SalesOrderListPageState();
}

class _SalesOrderListPageState extends State<SalesOrderListPage> {
  String _timeFilter = '30 Days';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SalesOrdersCubit>()..fetchSalesOrders(),
      child: Scaffold(
        appBar: const AuthenticatedAppBar(title: 'Sales'),
        body: BlocBuilder<SalesOrdersCubit, SalesOrdersState>(
          builder: (context, state) {
            if (state is SalesOrdersLoading || state is SalesOrdersInitial) {
              return _buildLoading(context);
            } else if (state is SalesOrdersError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<SalesOrdersCubit>().fetchSalesOrders(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (state is SalesOrdersEmpty) {
              return _buildSuccess(context, []);
            } else if (state is SalesOrdersSuccess) {
              return _buildSuccess(context, state.orders);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  List<SalesOrderModel> _filterOrders(List<SalesOrderModel> orders) {
    if (_timeFilter == 'All') return orders;
    final now = DateTime.now();
    int days = 30;
    if (_timeFilter == 'Today') days = 1;
    if (_timeFilter == '7 Days') days = 7;
    if (_timeFilter == '30 Days') days = 30;

    return orders.where((o) {
      try {
        final orderDate = DateTime.parse(o.dateOrder);
        return now.difference(orderDate).inDays <= days;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  Widget _buildLoading(BuildContext context) {
    final fakeOrders = List.generate(
      5,
      (i) => const SalesOrderModel(
        id: 0,
        name: 'Loading Order',
        customerName: 'Loading Customer Name',
        dateOrder: '2025-01-01 12:00:00',
        state: 'sale',
        amountTotal: 1234.56,
        orderLineIds: [],
      ),
    );

    return Skeletonizer(
      enabled: true,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _buildFilterRow(),
          const SizedBox(height: AppSpacing.lg),
          _buildKPIHeader(fakeOrders, isSkeleton: true),
          const SizedBox(height: AppSpacing.xxl),
          Text('Recent Orders', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          for (var o in fakeOrders) _buildOrderCard(context, o),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context, List<SalesOrderModel> allOrders) {
    final filtered = _filterOrders(allOrders);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        context.read<SalesOrdersCubit>().fetchSalesOrders();
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _buildFilterRow(),
          const SizedBox(height: AppSpacing.lg),
          _buildKPIHeader(filtered),
          const SizedBox(height: AppSpacing.xxl),
          Text('Orders', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: Center(
                child: Text(
                  'No orders in this period.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          for (var o in filtered) _buildOrderCard(context, o),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Overview', style: theme.textTheme.titleLarge),
        PopupMenuButton<String>(
          initialValue: _timeFilter,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          onSelected: (val) {
            setState(() => _timeFilter = val);
          },
          itemBuilder: (context) {
            return ['Today', '7 Days', '30 Days', 'All'].map((String value) {
              final isSelected = value == _timeFilter;
              return PopupMenuItem<String>(
                value: value,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                  ],
                ),
              );
            }).toList();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _timeFilter,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKPIHeader(
    List<SalesOrderModel> orders, {
    bool isSkeleton = false,
  }) {
    int totalItems = 0;
    double totalRevenue = 0.0;
    for (var o in orders) {
      totalItems += o.orderLineIds.length;
      totalRevenue += o.amountTotal;
    }
    double aov = orders.isNotEmpty ? totalRevenue / orders.length : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Orders',
                isSkeleton ? '12' : '${orders.length}',
                Icons.shopping_cart_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildKPICard(
                'Revenue',
                isSkeleton ? '\$12K' : '\$${totalRevenue.toStringAsFixed(0)}',
                Icons.attach_money,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'AOV',
                isSkeleton ? '\$1K' : '\$${aov.toStringAsFixed(0)}',
                Icons.analytics_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildKPICard(
                'Items',
                isSkeleton ? '45' : '$totalItems',
                Icons.inventory_2_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, SalesOrderModel order) {
    Color statusColor = AppColors.offline;
    if (order.state == 'sale' || order.state == 'done') {
      statusColor = AppColors.success;
    } else if (order.state == 'draft' || order.state == 'sent') {
      statusColor = AppColors.warning;
    }
    Color statusBg = statusColor.withValues(alpha: 0.15);

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            await context.push('/sales_order_details/${order.id}');
            if (context.mounted) {
              context.read<SalesOrdersCubit>().fetchSalesOrders();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order.name, style: theme.textTheme.titleMedium),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.displayState,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        order.customerName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          order.dateOrder.split(' ').first,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '\$${order.amountTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
