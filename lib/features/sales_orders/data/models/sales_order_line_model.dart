import 'package:equatable/equatable.dart';

class SalesOrderLineModel extends Equatable {
  final int id;
  final String productName;
  final double quantity;
  final double priceUnit;
  final double priceSubtotal;

  const SalesOrderLineModel({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.priceUnit,
    required this.priceSubtotal,
  });

  factory SalesOrderLineModel.fromMap(Map<String, dynamic> map) {
    String pName = 'Unknown Product';
    if (map['product_id'] is List && (map['product_id'] as List).length > 1) {
      pName = (map['product_id'] as List)[1].toString();
    } else if (map['name'] is String && (map['name'] as String).isNotEmpty) {
      pName = map['name'] as String;
    }

    return SalesOrderLineModel(
      id: map['id'] as int? ?? 0,
      productName: pName,
      quantity: (map['product_uom_qty'] as num?)?.toDouble() ?? 0.0,
      priceUnit: (map['price_unit'] as num?)?.toDouble() ?? 0.0,
      priceSubtotal: (map['price_subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productName,
    quantity,
    priceUnit,
    priceSubtotal,
  ];
}
