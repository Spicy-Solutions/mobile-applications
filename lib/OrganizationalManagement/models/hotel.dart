class Hotel {
  final int id;
  final String name;
  final String description;
  final String email;
  final String address;
  final String phone;
  final int ownerId;
  final String category;

  Hotel({
    required this.id,
    required this.name,
    required this.description,
    required this.email,
    required this.address,
    required this.phone,
    required this.ownerId,
    required this.category,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      email: json['email'],
      address: json['address'],
      phone: json['phone'],
      ownerId: json['ownerId'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'email': email,
      'address': address,
      'phone': phone,
      'ownerId': ownerId,
      'category': category,
    };
  }
}

