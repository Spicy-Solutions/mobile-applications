// models/hotel.dart
class Hotel {
  final int id;
  final String name;
  final String description;
  final String city;
  final String address;
  final String phone;
  final int ownerId;
  final String email;
  final String category;

  Hotel({
    required this.id,
    required this.name,
    required this.description,
    required this.city,
    required this.address,
    required this.phone,
    required this.ownerId,
    required this.email,
    required this.category,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    try {
      return Hotel(
        id: _parseInt(json['id']) ?? 0,
        name: json['name']?.toString() ?? 'Hotel',
        description: json['description']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        ownerId: _parseInt(json['ownerId']) ?? 0,
        email: json['email']?.toString() ?? '',        category: json['category']?.toString() ?? 'SUITE',
      );
    } catch (e) {
      print('Error in Hotel.fromJson: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    try {
      if (value is int) {
        return value;
      }
      if (value is String) {
        return int.parse(value);
      }
      if (value is double) {
        return value.toInt();
      }
      return 0;
    } catch (e) {
      print('Error parsing int: $value - $e');
      return 0;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'city': city,
      'address': address,
      'phone': phone,
      'ownerId': ownerId,
      'email': email,
      'category': category,
    };
  }
}