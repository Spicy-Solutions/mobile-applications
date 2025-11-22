class Provider {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String state;

  Provider({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.state,
  });

  factory Provider.fromJson(Map<String, dynamic> json) {
    return Provider(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      state: json['state'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'state': state,
    };
  }
}
