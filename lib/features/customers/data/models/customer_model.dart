import 'package:equatable/equatable.dart';

class CustomerModel extends Equatable {
  final int id;
  final String name;
  final String phone;
  final String city;
  final String email;
  final String address;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.city,
    required this.email,
    required this.address,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    final street = map['street'] as String? ?? '';
    final city = map['city'] as String? ?? '';
    final stateId = map['state_id'] is List
        ? map['state_id'][1] as String?
        : '';
    final countryId = map['country_id'] is List
        ? map['country_id'][1] as String?
        : '';

    final List<String> addressParts = [
      street,
      city,
      stateId ?? '',
      countryId ?? '',
    ].where((part) => part.isNotEmpty).toList();

    final address = addressParts.isEmpty
        ? 'Not available'
        : addressParts.join(', ');

    return CustomerModel(
      id: map['id'] as int,
      name: map['name'] as String? ?? 'Unknown',
      phone: map['phone'] as String? ?? 'Not available',
      city: city.isEmpty ? 'Not available' : city,
      email: map['email'] as String? ?? 'Not available',
      address: address,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'city': city,
      'email': email,
      'address': address,
    };
  }

  factory CustomerModel.fromCache(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as int,
      name: map['name'] as String,
      phone: map['phone'] as String,
      city: map['city'] as String,
      email: map['email'] as String,
      address: map['address'] as String,
    );
  }

  CustomerModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? city,
    String? email,
    String? address,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      email: email ?? this.email,
      address: address ?? this.address,
    );
  }

  @override
  List<Object?> get props => [id, name, phone, city, email, address];
}
