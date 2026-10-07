import 'package:equatable/equatable.dart';
import 'package:sales_odoo_app/features/sales_orders/data/models/sales_order_line_model.dart';
import 'package:sales_odoo_app/features/sales_orders/data/models/sales_order_model.dart';

abstract class SalesOrdersState extends Equatable {
  const SalesOrdersState();

  @override
  List<Object?> get props => [];
}

class SalesOrdersInitial extends SalesOrdersState {}

class SalesOrdersLoading extends SalesOrdersState {}

class SalesOrdersSuccess extends SalesOrdersState {
  final List<SalesOrderModel> orders;

  const SalesOrdersSuccess(this.orders);

  @override
  List<Object?> get props => [orders];
}

class SalesOrdersEmpty extends SalesOrdersState {}

class SalesOrdersError extends SalesOrdersState {
  final String message;

  const SalesOrdersError(this.message);

  @override
  List<Object?> get props => [message];
}

class SalesOrderDetailLoading extends SalesOrdersState {}

class SalesOrderDetailSuccess extends SalesOrdersState {
  final SalesOrderModel order;
  final List<SalesOrderLineModel> lines;
  final bool isPendingConfirmation;

  const SalesOrderDetailSuccess(
    this.order,
    this.lines, {
    this.isPendingConfirmation = false,
  });

  @override
  List<Object?> get props => [order, lines, isPendingConfirmation];
}

class SalesOrderConfirming extends SalesOrdersState {
  final SalesOrderModel order;
  final List<SalesOrderLineModel> lines;

  const SalesOrderConfirming(this.order, this.lines);

  @override
  List<Object?> get props => [order, lines];
}

class SalesOrderDetailError extends SalesOrdersState {
  final String message;

  const SalesOrderDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
