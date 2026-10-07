import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sales_odoo_app/core/di/injection.dart';
import 'package:sales_odoo_app/core/theme/app_theme.dart';
import 'package:sales_odoo_app/core/presentation/widgets/authenticated_app_bar.dart';
import 'package:sales_odoo_app/features/customers/data/models/customer_model.dart';
import 'package:sales_odoo_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:sales_odoo_app/features/customers/presentation/cubit/customers_state.dart';
import 'package:sales_odoo_app/features/customers/presentation/widgets/customer_list_item.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query, BuildContext context) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<CustomersCubit>().fetchCustomers(searchQuery: query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CustomersCubit>()..fetchCustomers(),
      child: Scaffold(
        appBar: const AuthenticatedAppBar(title: 'Customers'),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Builder(
                builder: (context) {
                  return TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Customers',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                context.read<CustomersCubit>().fetchCustomers();
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) {
                      setState(() {});
                      _onSearchChanged(val, context);
                    },
                  );
                },
              ),
            ),
            Expanded(
              child: BlocBuilder<CustomersCubit, CustomersState>(
                builder: (context, state) {
                  if (state is CustomersLoading || state is CustomersInitial) {
                    final fakeCustomers = List.generate(
                      5,
                      (index) => const CustomerModel(
                        id: 0,
                        name: 'Loading Customer Name',
                        email: 'loading@example.com',
                        phone: '+1 234 567 8900',
                        city: 'Loading City',
                        address: 'Loading Address',
                      ),
                    );
                    return Skeletonizer(
                      enabled: true,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        itemCount: fakeCustomers.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          return CustomerListItem(
                            customer: fakeCustomers[index],
                            onTap: () {},
                          );
                        },
                      ),
                    );
                  } else if (state is CustomersError) {
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
                                context.read<CustomersCubit>().fetchCustomers(
                                  searchQuery: _searchController.text,
                                ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  } else if (state is CustomersEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            _searchController.text.isEmpty
                                ? 'No customers found.'
                                : 'No customers match your search.',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    );
                  } else if (state is CustomersSuccess) {
                    final customers = state.customers;
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: customers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        return CustomerListItem(
                          customer: customer,
                          onTap: () async {
                            await context.push(
                              '/customer_details',
                              extra: customer.id,
                            );
                            if (context.mounted) {
                              context.read<CustomersCubit>().fetchCustomers(
                                searchQuery: _searchController.text,
                              );
                            }
                          },
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
