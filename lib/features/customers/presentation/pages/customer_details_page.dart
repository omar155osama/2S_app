import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_odoo_app/core/di/injection.dart';
import 'package:sales_odoo_app/core/theme/app_theme.dart';
import 'package:sales_odoo_app/features/customers/data/models/customer_model.dart';
import 'package:sales_odoo_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:sales_odoo_app/features/customers/presentation/cubit/customers_state.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CustomerDetailsPage extends StatefulWidget {
  final int customerId;

  const CustomerDetailsPage({super.key, required this.customerId});

  @override
  State<CustomerDetailsPage> createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length > 1 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<CustomersCubit>()..fetchCustomerDetails(widget.customerId),
      child: Scaffold(
        appBar: AppBar(title: const Text('Customer Profile')),
        body: BlocConsumer<CustomersCubit, CustomersState>(
          listenWhen: (previous, current) {
            return current is CustomerDetailSuccess;
          },
          listener: (context, state) {
            if (state is CustomerDetailSuccess) {
              if (_phoneController.text.isEmpty ||
                  _phoneController.text != state.customer.phone) {
                _phoneController.text = state.customer.phone;
              }
            } else if (state is CustomerDetailError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is CustomerDetailLoading) {
              return _buildLoading(context);
            } else if (state is CustomerDetailError &&
                _phoneController.text.isEmpty) {
              return _buildError(context, state.message);
            }

            CustomerModel? customer;
            bool isSaving = false;
            bool isPending = false;

            if (state is CustomerDetailSuccess) {
              customer = state.customer;
              isPending = state.isPendingSync;
            } else if (state is CustomerDetailSaving) {
              customer = state.customer;
              isSaving = true;
            } else if (state is CustomerDetailError) {
              // Retain previous state visually
            }

            if (customer != null) {
              if (_phoneController.text.isEmpty && !isSaving) {
                _phoneController.text = customer.phone;
              }
              return _buildContent(context, customer, isSaving, isPending);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final fakeCustomer = const CustomerModel(
      id: 0,
      name: 'Loading Customer Name',
      email: 'loading@example.com',
      phone: '+1 234 567 8900',
      city: 'Loading City',
      address: 'Loading Address',
    );
    return Skeletonizer(
      enabled: true,
      child: _buildContent(
        context,
        fakeCustomer,
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
                .read<CustomersCubit>()
                .fetchCustomerDetails(widget.customerId),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    CustomerModel customer,
    bool isSaving,
    bool isPending, {
    bool isSkeleton = false,
  }) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
                const Icon(Icons.sync_problem, color: AppColors.warning),
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
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  _getInitials(customer.name),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                customer.name,
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                customer.city.isNotEmpty
                    ? customer.city
                    : 'No location provided',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        Text(
          'Contact Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildDetailItem(
                icon: Icons.email_outlined,
                label: 'Email',
                value: customer.email,
                readOnly: true,
              ),
              const Divider(),
              _buildDetailItem(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: customer.phone,
                readOnly: false,
                isSaving: isSaving,
                context: context,
              ),
              const Divider(),
              _buildDetailItem(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: customer.address,
                readOnly: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required bool readOnly,
    bool isSaving = false,
    BuildContext? context,
  }) {
    context ??= this.context;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (readOnly)
                  Text(
                    value.isNotEmpty ? value : 'N/A',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () {
                                FocusScope.of(context!).unfocus();
                                context
                                    .read<CustomersCubit>()
                                    .updateCustomerPhone(
                                      widget.customerId,
                                      _phoneController.text,
                                    );
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
