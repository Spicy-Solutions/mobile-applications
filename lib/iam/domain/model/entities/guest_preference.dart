class GuestPreferences {
  final int id;

  final int guestId;

  final int temperature;

  GuestPreferences(
      {required this.id, required this.guestId, required this.temperature});

  factory GuestPreferences.fromJson(Map<String, dynamic> json) {
    return GuestPreferences(
      id: json['id'] as int,
      guestId: json['guestId'] as int,
      temperature: json['temperature'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guestId': guestId,
      'temperature': temperature,
    };
  }
}