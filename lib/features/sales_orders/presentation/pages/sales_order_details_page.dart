import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_odoo_app/core/di/injection.dart';
import 'package:sales_odoo_app/core/theme/app_theme.dart';
import 'package:sales_odoo_app/features/sales_orders/data/models/sales_order_line_model.dart';
import 'package:sales_odoo_app/features/sales_orders/data/models/sales_order_model.dart';
import 'package:sales_odoo_app/features/sales_orders/presentation/cubit/sales_orders_cubit.dart';
import 'package:sales_odoo_app/features/sales_orders/presentation/cubit/sales_orders_state.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SalesOrderDetailsPage extends StatelessWidget {
  final int orderId;

  const SalesOrderDetailsPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SalesOrdersCubit>()..fetchSalesOrderDetails(orderId),
      child: Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: BlocConsumer<SalesOrdersCubit, SalesOrdersState>(
          listener: (context, state) {
            if (state is SalesOrderDetailError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is SalesOrderDetailLoading ||
                state is SalesOrdersInitial) {
              return _buildLoading(context);
            } else if (state is SalesOrderDetailError) {
              return _buildError(context, state.message);
            }

            SalesOrderModel? order;
            List<SalesOrderLineModel> lines = [];
            bool isConfirming = false;
            bool isPending = false;

            if (state is SalesOrderDetailSuccess) {
              order = state.order;
              lines = state.lines;
              isPending = state.isPendingConfirmation;
            } else if (state is SalesOrderConfirming) {
              order = state.order;
              lines = state.lines;
              isConfirming = true;
            }

            if (order != null) {
              return _buildContent(
                context,
                order,
                lines,
                isConfirming,
                isPending,
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final fakeOrder = const SalesOrderModel(
      id: 0,
      name: 'S00000',
      customerName: 'Loading Customer Name',
      dateOrder: '2026-10-01 12:00:00',
      state: 'sale',
      amountTotal: 999.99,
      orderLineIds: [1, 2],
    );
    final fakeLines = List.generate(
      2,
      (i) => const SalesOrderLineModel(
        id: 0,
        productName: 'Loading Product',
        quantity: 1,
        priceUnit: 100,
        priceSubtotal: 100,
      ),
    );
    return Skeletonizer(
      enabled: true,
      child: _buildContent(
        context,
        fakeOrder,
        fakeLines,
        false,
        false,
        isSkeleton: true,
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () => context
                .read<SalesOrdersCubit>()
                .fetchSalesOrderDetails(orderId),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SalesOrderModel order,
    List<SalesOrderLineModel> lines,
    bool isConfirming,
    bool isPending, {
    bool isSkeleton = false,
  }) {
    final canConfirm = (order.state == 'draft' || order.state == 'sent');

    Color statusColor = AppColors.offline;
    Color statusBg = AppColors.offlineSoft;
    if (order.state == 'sale' || order.state == 'done') {
      statusColor = AppColors.success;
      statusBg = AppColors.successSoft;
    } else if (order.state == 'draft' || order.state == 'sent') {
      statusColor = AppColors.warning;
      statusBg = AppColors.warningSoft;
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPending)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.warningSoft,
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sync_problem,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Saved offline — waiting for sync',
                            style: TextStyle(
                              color: AppColors.warning.withValues(alpha: 0.9),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.name,
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                order.displayState,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const Divider(),
                        const SizedBox(height: AppSpacing.md),
                        _buildSummaryRow(
                          Icons.person_outline,
                          'Customer',
                          order.customerName,
                          context,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildSummaryRow(
                          Icons.calendar_today,
                          'Date',
                          order.dateOrder,
                          context,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                if (canConfirm)
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: (isConfirming || isPending)
                          ? null
                          : () => context
                                .read<SalesOrdersCubit>()
                                .confirmSalesOrder(order.id),
                      icon: isConfirming
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        isPending ? 'Saved offline' : 'Confirm Order',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxxl,
                          vertical: AppSpacing.lg,
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Products',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final line = lines[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${line.quantity} units x \$${line.priceUnit.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${line.priceSubtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }, childCount: lines.length),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '\$${order.amountTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    IconData icon,
    String label,
    String value,
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          '$label:',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
