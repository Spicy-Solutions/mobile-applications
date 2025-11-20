class Owner {
  final int id;

  final String name;

  final String surname;

  final String phone;

  final String email;

  final String photoURL;

  final String state;

  Owner(
      {required this.id,
      required this.name,
      required this.surname,
      required this.phone,
      required this.email,
      required this.photoURL,
      required this.state});

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      id: json['id'] as int,
      name: json['name'] as String,
      surname: json['surname'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      photoURL: json['photoURL'] as String,
      state: json['state'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'phone': phone,
      'email': email,
      'photoURL': photoURL,
      'state': state,
    };
  }
}