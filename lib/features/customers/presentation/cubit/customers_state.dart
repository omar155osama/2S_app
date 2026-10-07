import 'package:equatable/equatable.dart';
import 'package:sales_odoo_app/features/customers/data/models/customer_model.dart';

abstract class CustomersState extends Equatable {
  const CustomersState();

  @override
  List<Object?> get props => [];
}

class CustomersInitial extends CustomersState {}

class CustomersLoading extends CustomersState {}

class CustomersSuccess extends CustomersState {
  final List<CustomerModel> customers;

  const CustomersSuccess(this.customers);

  @override
  List<Object?> get props => [customers];
}

class CustomersEmpty extends CustomersState {}

class CustomersError extends CustomersState {
  final String message;

  const CustomersError(this.message);

  @override
  List<Object?> get props => [message];
}

// For individual customer details
class CustomerDetailLoading extends CustomersState {}

class CustomerDetailSaving extends CustomersState {
  final CustomerModel customer;
  const CustomerDetailSaving(this.customer);

  @override
  List<Object?> get props => [customer];
}

class CustomerDetailSuccess extends CustomersState {
  final CustomerModel customer;
  final bool isPendingSync;

  const CustomerDetailSuccess(this.customer, {this.isPendingSync = false});

  @override
  List<Object?> get props => [customer, isPendingSync];
}

class CustomerDetailError extends CustomersState {
  final String message;

  const CustomerDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
