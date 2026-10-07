import 'package:equatable/equatable.dart';

class SalesOrderModel extends Equatable {
  final int id;
  final String name;
  final String customerName;
  final String dateOrder;
  final String state;
  final double amountTotal;
  final List<int> orderLineIds;

  const SalesOrderModel({
    required this.id,
    required this.name,
    required this.customerName,
    required this.dateOrder,
    required this.state,
    required this.amountTotal,
    required this.orderLineIds,
  });

  factory SalesOrderModel.fromMap(Map<String, dynamic> map) {
    String customer = 'Unknown';
    if (map['partner_id'] is List && (map['partner_id'] as List).length > 1) {
      customer = (map['partner_id'] as List)[1].toString();
    } else if (map['partner_id'] is String) {
      customer = map['partner_id'] as String;
    }

    List<int> lines = [];
    if (map['order_line'] is List) {
      lines = (map['order_line'] as List).map((e) => e as int).toList();
    }

    return SalesOrderModel(
      id: map['id'] as int? ?? 0,
      name: map['name']?.toString() ?? '',
      customerName: customer,
      dateOrder: map['date_order']?.toString() ?? '',
      state: map['state']?.toString() ?? 'draft',
      amountTotal: (map['amount_total'] as num?)?.toDouble() ?? 0.0,
      orderLineIds: lines,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'partner_id': customerName,
      'date_order': dateOrder,
      'state': state,
      'amount_total': amountTotal,
      'order_line': orderLineIds,
    };
  }

  SalesOrderModel copyWith({
    int? id,
    String? name,
    String? customerName,
    String? dateOrder,
    String? state,
    double? amountTotal,
    List<int>? orderLineIds,
  }) {
    return SalesOrderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      customerName: customerName ?? this.customerName,
      dateOrder: dateOrder ?? this.dateOrder,
      state: state ?? this.state,
      amountTotal: amountTotal ?? this.amountTotal,
      orderLineIds: orderLineIds ?? this.orderLineIds,
    );
  }

  String get displayState {
    switch (state) {
      case 'draft':
        return 'Quotation';
      case 'sent':
        return 'Quotation Sent';
      case 'sale':
        return 'Sales Order';
      case 'done':
        return 'Locked';
      case 'cancel':
        return 'Cancelled';
      default:
        return state;
    }
  }

  @override
  List<Object?> get props => [
    id,
    name,
    customerName,
    dateOrder,
    state,
    amountTotal,
    orderLineIds,
  ];
}
